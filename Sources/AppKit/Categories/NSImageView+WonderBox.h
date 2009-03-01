/*
 *  NSImageView+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

@interface NSImageView (WBSimpleImageView)
/*!
@method
 @abstract Create and configure an NSImageView that just draws an image.
 */
- (id)initWithImage:(NSImage *)image;
@end
