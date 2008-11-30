/*
 *  NSImage+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSImage+WonderBox.h)

@implementation NSImage (WBImageNamedInBundle)

+ (id)imageNamed:(NSString *)name inBundleWithIdentifier:(NSBundle *)bundle {
  NSImage *image = nil;
  if (name) {
    /* First check internal cache */
    image = [NSImage imageNamed:name];
    if (!image) {
      /* Then search bundle resource */
      NSString *path = bundle ? [bundle pathForImageResource:name] : nil;
      image = path ? [[NSImage alloc] initWithContentsOfFile:path] : nil;
      if (image) {
        [image setName:name];
        [image autorelease];
      } else {
        DLog(@"Unable to find image %@ in bundle %@", name, [bundle bundleIdentifier]);
      }
    }
  }
  return image;
}

+ (id)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
  return [self imageNamed:name inBundleWithIdentifier:bundle];
}

@end
