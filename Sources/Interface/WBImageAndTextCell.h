/*
 *  WBImageAndTextCell.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

WB_CLASS_EXPORT
@interface WBImageAndTextCell : NSTextFieldCell {
  @private
  NSImage	*wb_image;
  struct _wb_itcFlags {
    unsigned int line:1;
    unsigned int reserved:31;
  } wb_itcFlags;
}

+ (id)cell;

- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

- (BOOL)drawsLineOver;
- (void)setDrawsLineOver:(BOOL)flag;

- (NSRect)titleRectForBounds:(NSRect)theRect;

@end
