/*
 *  WBImageAndTextCell.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
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
