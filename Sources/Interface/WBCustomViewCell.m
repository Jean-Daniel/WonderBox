/*
 *  WBCustomViewCell.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBCustomViewCell.h>

@implementation WBCustomViewCell

- (void)setObjectValue:(id)anObject {
  NSParameterAssert(nil == anObject || [anObject isKindOfClass:[NSView class]]);
  if (anObject != wb_subview && (nil == anObject || [anObject isKindOfClass:[NSView class]])) {
    // Weak reference
    wb_subview = anObject;
  }
}

- (void)dealloc {
  wb_subview = nil;
  [super dealloc];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [super drawWithFrame:cellFrame inView:controlView];
  if (wb_subview) {
    [wb_subview setFrame:cellFrame];
    NSView *parent = [wb_subview superview];
    if (parent != controlView) {
      if (parent) {
        [wb_subview retain];
        [wb_subview removeFromSuperview];
      }
      [controlView addSubview:wb_subview];
      if (parent)
        [wb_subview release];
    }
  }
}

@end

#pragma mark -
@implementation WBTrapView
- (NSView *)hitTest:(NSPoint)aPoint {
  return self;
}

@end
