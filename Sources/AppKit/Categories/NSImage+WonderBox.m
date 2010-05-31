/*
 *  NSImage+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSImage+WonderBox.h)

// cache missing image to avoid disk lookup and warning log for each call.
static NSMutableSet *sMissingImages = nil;

@implementation NSImage (WBImageNamedInBundle)

+ (id)imageNamed:(NSString *)name inBundleWithIdentifier:(NSBundle *)bundle {
  if (!name) return nil;

  NSImage *image = nil;
  /* First check internal cache */
  if (sMissingImages && [sMissingImages containsObject:name])
    return nil;
  // then check NSImage cache
  image = [NSImage imageNamed:name];
  if (!image) {
    /* Then search bundle resource */
    NSString *path = bundle ? [bundle pathForImageResource:name] : nil;
    image = path ? [[NSImage alloc] initWithContentsOfFile:path] : nil;
    if (image) {
      [image setName:name];
      [image autorelease];
    } else {
      WBLogWarning(@"Unable to find image named '%@' in bundle '%@'", name, [bundle bundleIdentifier]);
      if (!sMissingImages)
        sMissingImages = [[NSMutableSet alloc] init];
      [sMissingImages addObject:name];
    }
  }
  return image;
}

+ (id)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
  return [self imageNamed:name inBundleWithIdentifier:bundle];
}

@end
