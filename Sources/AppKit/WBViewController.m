/*
 *  WBViewController.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBViewController.h)

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

@implementation WBViewController

- (id)init {
  return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)aBundle {
  if (self = [super init]) {
    wb_name = [name copy];
    wb_bundle = [aBundle retain];
  }
  return self;
}

- (void)dealloc {
	[wb_representedObject release];
	[wb_bundle release];
	[wb_title release];
  [wb_root release];
	[wb_name release];
  [view release];
  [super dealloc];
}

- (void)loadView {
  if (!view) {
		if (![self nibName])
			WBThrowException(NSInvalidArgumentException, @"view controller cannot load a view when name is nil.");
		
    NSNib *nib = [[NSNib alloc] initWithNibNamed:[self nibName] bundle:[self nibBundle]];
    if ([nib instantiateNibWithOwner:self topLevelObjects:&wb_root]) {
      [wb_root retain];
      /* Release root objects */
      [wb_root makeObjectsPerformSelector:@selector(release)];
    } else {
      DLog(@"Cannot load nib file: %@", wb_name);
    }
    [nib release];
  }
}

- (NSString *)nibName {
  return wb_name;
}
- (NSBundle *)nibBundle {
  return wb_bundle;
}

- (NSView *)view {
  if (!view)
    [self loadView];
  return view;
}
/* Called by Nib Loader */
- (void)setView:(NSView *)aView {
  WBSetterRetain(&view, aView);
}

- (NSString *)title {
  return wb_title;
}
- (void)setTitle:(NSString *)string {
  WBSetterCopy(&wb_title, string);
}

- (id)representedObject {
	return wb_representedObject;
}
- (void)setRepresentedObject:(id)representedObject {
	WBSetterRetain(&wb_representedObject, representedObject);
}

@end

#endif
