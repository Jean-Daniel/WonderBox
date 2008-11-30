/*
 *  NSImage+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@interface NSImage (WBImageNamedInBundle)
/*!
@method     imageNamed:inBundle:
 @abstract   Act as +imageNamed: method but search in a specified Bundle instead of searching mainBundle only.
 @param      name The name of the image you want find.
 @param      bundle The bundle containing this image.
 @result     Returns the image if find one, or nil if no image were found.
 */
+ (id)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
+ (id)imageNamed:(NSString *)name inBundleWithIdentifier:(NSBundle *)bundle;

@end


