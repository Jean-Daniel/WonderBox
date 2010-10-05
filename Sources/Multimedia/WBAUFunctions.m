/*
 *  WBAUFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBAUFunctions.h)

#import <AudioUnit/AUCocoaUIView.h>
#import <CoreAudioKit/CoreAudioKit.h>

static
bool _WBAUCocoaViewIsValid(Class pluginClass) {
	if ([pluginClass conformsToProtocol:@protocol(AUCocoaUIBase)]) {
		if ([pluginClass instancesRespondToSelector:@selector(interfaceVersion)] &&
        [pluginClass instancesRespondToSelector:@selector(uiViewForAudioUnit:withSize:)]) {
			return true;
		}
	}
  return false;
}

NSView *WBAUInstanciateViewFromAudioUnit(AudioUnit anUnit, NSSize aSize) {
	// get AU's Cocoa view property
  UInt32 dataSize = 0;
  Boolean isWritable;
  UInt32 numberOfClasses;
  AudioUnitCocoaViewInfo * cocoaViewInfo = NULL;

  OSStatus result = AudioUnitGetPropertyInfo(anUnit, kAudioUnitProperty_CocoaUI,
                                             kAudioUnitScope_Global, 0, &dataSize, &isWritable);

  numberOfClasses = (dataSize - sizeof(CFURLRef)) / sizeof(CFStringRef);

  NSURL *bundleURL = nil;
  NSString *factoryClassName = nil;

	// Does view have custom Cocoa UI?
  if ((result == noErr) && (numberOfClasses > 0) ) {
    cocoaViewInfo = (AudioUnitCocoaViewInfo *)malloc(dataSize);
    if(AudioUnitGetProperty(anUnit, kAudioUnitProperty_CocoaUI,
                            kAudioUnitScope_Global, 0, cocoaViewInfo, &dataSize) == noErr) {
      bundleURL	= (NSURL *)cocoaViewInfo->mCocoaAUViewBundleLocation;
			// we only take the first view in this example.
      factoryClassName = [[(id)cocoaViewInfo->mCocoaAUViewClass[0] retain] autorelease];
    } else {
      if (cocoaViewInfo != NULL) {
				free (cocoaViewInfo);
				cocoaViewInfo = NULL;
			}
    }
  }

	NSView *AUView = nil;
	// Show custom UI if view has it
	if (bundleURL && factoryClassName) {
		NSBundle *viewBundle = [NSBundle bundleWithPath:[bundleURL path]];
		if (viewBundle == nil) {
			NSLog (@"Error loading AU view's bundle");
		} else {
			Class factoryClass = [viewBundle classNamed:factoryClassName];
			WBAssert(factoryClass != nil, @"Error getting AU view's factory class from bundle");

			// make sure 'factoryClass' implements the AUCocoaUIBase protocol
			WBAssert(_WBAUCocoaViewIsValid(factoryClass),
                @"AU view's factory class does not properly implement the AUCocoaUIBase protocol");

			// make a factory
			id<AUCocoaUIBase> factoryInstance = [[[factoryClass alloc] init] autorelease];
			WBAssert (factoryInstance != nil, @"Could not create an instance of the AU view factory");
			// make a view
			AUView = [factoryInstance	uiViewForAudioUnit:anUnit withSize:aSize];
    }

    // cleanup
    if (cocoaViewInfo) {
      if (cocoaViewInfo->mCocoaAUViewBundleLocation)
        CFRelease(cocoaViewInfo->mCocoaAUViewBundleLocation);

      for (UInt32 i = 0; i < numberOfClasses; i++)
        if (cocoaViewInfo->mCocoaAUViewClass[i])
          CFRelease(cocoaViewInfo->mCocoaAUViewClass[i]);

      free (cocoaViewInfo);
    }
  }

	if (!AUView) { // No custom view (or failed to load), show generic Cocoa view
		AUView = [[[AUGenericView alloc] initWithAudioUnit:anUnit] autorelease];
		[(AUGenericView *)AUView setShowsExpertParameters:NO];
  }

  return AUView;
}
