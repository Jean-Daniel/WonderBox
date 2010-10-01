/*
 *  WBImageAndTextView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

WB_CLASS_EXPORT
@interface WBImageAndTextView : NSView {
  @private
  CGFloat wb_width;
  NSImage *wb_icon;
  NSString *wb_title;

  id wb_target;
  SEL wb_action;
  struct _wb_saFlags {
    unsigned int dark:1;
    unsigned int align:4;
    unsigned int highlight:1;
    unsigned int reserved:26;
  } wb_saFlags;
}

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anImage;

- (NSString *)title;
- (void)setTitle:(NSString *)title;

- (id)target;
- (void)setTarget:(id)aTarget;

- (SEL)action;
- (void)setAction:(SEL)anAction;

@end

