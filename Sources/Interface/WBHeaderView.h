/*
 *  WBHeaderView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

typedef enum {
  kWBHeaderLeft = 1 << 0,
  kWBHeaderRight = 1 << 1
} WBHeaderPosition;

WB_OBJC_EXPORT
@interface WBHeaderView : NSView {
  @private
  struct _wb_xhFlags {
    unsigned int left:1;
    unsigned int right:1;
    unsigned int :6;
  } wb_xhFlags;
  CGFloat wb_leftPadding;
  CGFloat wb_rightPadding;
  NSMutableArray *wb_left, *wb_right;
}

- (NSUInteger)drawsBorder;
- (void)setDrawsBorder:(NSUInteger)border;

- (CGFloat)paddingForPosition:(WBHeaderPosition)aPosition;
- (void)setPadding:(CGFloat)padding forPosition:(WBHeaderPosition)aPosition;

- (NSButton *)addButton:(NSImage *)anImage position:(WBHeaderPosition)position;
- (NSPopUpButton *)addMenu:(NSMenu *)aMenu position:(WBHeaderPosition)position;

@end
