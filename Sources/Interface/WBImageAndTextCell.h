/*
 *  WBImageAndTextCell.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTextFieldCell.h>

WB_OBJC_EXPORT
@interface WBImageAndTextCell : WBTextFieldCell <NSCopying, NSCoding> {
@private
  NSImage *wb_image;
}

- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

- (NSRect)titleRectForBounds:(NSRect)theRect;

@end
