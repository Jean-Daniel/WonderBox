/*
 *  WBBezelLegacy.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBBezelLegacy.h"

@interface _WBSimpleBezelView : NSView

@end

@interface WBBezelLegacyLevelBar : NSView
@property(nonatomic) CGFloat levelValue;
@end

@implementation _WBSimpleBezelView

- (void)drawRect:(NSRect)rect {
  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.frame xRadius:25 yRadius:25];
  [[NSColor colorWithCalibratedWhite:0 alpha:.15] setFill];
  [path fill];
}

@end

@implementation WBLegacyBezelWindow {
  WBBezelLegacyLevelBar *_levelBar;
}

- (instancetype)initWithImageView:(NSImageView *)aView {
  if (self = [super initWithImageView:aView]) {
    NSSize s = self.frame.size;
    self.contentView = [[[_WBSimpleBezelView alloc] initWithFrame:CGRectMake(0, 0, s.width, s.height)] autorelease];
    [self.contentView addSubview:aView];

    _levelBar = [[WBBezelLegacyLevelBar alloc] initWithFrame:CGRectMake(20, 20, 161, 8)];
  }
  return self;
}

- (void)dealloc {
  [_levelBar release];
  [super dealloc];
}

- (CGFloat)levelValue {
  return _levelBar.levelValue;
}
- (void)setLevelValue:(CGFloat)levelValue {
  _levelBar.levelValue = levelValue;
}

- (BOOL)isLevelBarVisible {
  return [_levelBar superview] != nil;
}

- (void)setLevelBarVisible:(BOOL)levelBarVisible {
  if (levelBarVisible && ![_levelBar superview]) {
    [self.imageView addSubview:_levelBar];
  } else if (!levelBarVisible && [_levelBar superview]) {
    [_levelBar removeFromSuperview];
  }
}

@end

// MARK: -
@implementation WBBezelLegacyLevelBar

- (void)setLevelValue:(CGFloat)levelValue {
  _levelValue = MIN(1., MAX(0., levelValue));
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetGrayFillColor(ctxt, 0, .45);
  CGContextFillRect(ctxt, self.bounds);

  CGContextSetGrayFillColor(ctxt, 1, 1);

  double one = 0.0625;
  int blocks = (int)(_levelValue / one);
  CGRect block = CGRectMake(1, 1, 9, 6);
  for (int idx = 0; idx < blocks; ++idx) {
    // Draw complete block
    CGContextFillRect(ctxt, block);
    block.origin.x += 10;
  }
  CGFloat fract;
  fract = modf(_levelValue / one, &fract);
  if (fract > 0.01) {
    block.size.width = fract * 9;
    block = [self backingAlignedRect:block options:
             NSAlignWidthNearest | NSAlignMaxXNearest | NSAlignHeightNearest | NSAlignMaxYNearest];
    if (block.size.width > 0)
      CGContextFillRect(ctxt, block);
  }
}

@end
