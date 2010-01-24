/*
 *  WBImageAndTextView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBImageAndTextView.h)

#import WBHEADER(WBCGFunctions.h)

static CGColorRef sShadowColor;

static const CGFloat kAVMargin = 16;
static const CGFloat kAVImageSize = 26;
static const CGFloat kAVImageRightMargin = 6;

/*
 Recommanded height: 31 pixels.
 */
@implementation WBImageAndTextView

+ (void)load {
  /* 1, (0; -1) */
  sShadowColor = WBCGColorCreateGray(.786, 1);
}

- (void)dealloc {
  [wb_icon release];
  [wb_title release];
  [super dealloc];
}

#pragma mark -
- (BOOL)acceptsFirstResponder {
  return wb_action != nil && [[NSApp currentEvent] type] == NSKeyDown;
}

- (BOOL)becomeFirstResponder {
  [self setNeedsDisplay:YES];
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  /* Cleanup Focus ring */
  NSRect frame = [self frame];
  frame.origin.x -= 4;
  frame.origin.y -= 4;
  frame.size.width += 8;
  frame.size.height += 8;
  [[self superview] setNeedsDisplayInRect:frame];
  /* Redraw self */
  [self setNeedsDisplay:YES];
  return [super resignFirstResponder];
}

- (BOOL)isOpaque {
  return NO;
}

- (id)target {
  return wb_target;
}
- (void)setTarget:(id)aTarget {
  wb_target = aTarget;
}

- (SEL)action {
  return wb_action;
}
- (void)setAction:(SEL)anAction {
  wb_action = anAction;
}

- (void)viewDidMoveToWindow {
  /* Set dark if window is not textured */
  BOOL flag = ([[self window] styleMask] & NSTexturedBackgroundWindowMask) == 0;
  WBFlagSet(wb_saFlags.dark, flag);
}

- (NSImage *)icon {
  return wb_icon;
}
- (void)setIcon:(NSImage *)anImage {
  WBSetterRetain(wb_icon, anImage);
}
- (NSString *)title {
  return wb_title;
}
- (void)setTitle:(NSString *)title {
  if (title != wb_title) {
    /* Cache informations */
    [wb_title release];
    wb_title = [title copy];
    
    wb_width = wb_title ? [wb_title sizeWithAttributes:nil].width : 0;
    
    NSRect frame = [self frame];
    NSRect dirty = frame;
    if (wb_width > 0) {
      CGFloat x = 0;
      switch (wb_saFlags.align) {
        case 0: /* center */
          x = AVG(NSWidth([[self superview] bounds]), - (wb_width + kAVImageSize + kAVImageRightMargin));
          x -= kAVMargin;
          /* Make sure x is an integer value */
          x = floor(x);
          break;
        case 1: /* left */
          x = 0;
          break;
        case 2: /* right */
          x = NSWidth([self bounds]) - (wb_width + kAVImageSize + kAVImageRightMargin);
          
          break;
      }
      
      frame.origin.x = x;
      frame.size.width = wb_width + kAVImageSize + kAVImageRightMargin + 2 * kAVMargin + 1;
      
      if (NSWidth(frame) > NSWidth([self bounds])) {
        dirty = frame;
      }
    } else {
      CGFloat x = 0;
      switch (wb_saFlags.align) {
        case 0: /* center */
          x = NSWidth([self bounds]) / 2;
          break;
        case 1: /* left */
          x = 0;
          break;
        case 2: /* right */
          x = NSWidth([self bounds]);
          break;
      }
      frame.origin.x += x;
    }
    [self setFrame:frame];
    [[self superview] setNeedsDisplayInRect:dirty];
  }
}

- (void)drawRect:(NSRect)rect {
  if ([self title] || [self icon]) {
    CGContextRef ctxt = WBCGContextGetCurrent();
    
    CGContextSetShouldAntialias(ctxt, true);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    // FIXME: userspace scale factor
    CGRect cgrect = CGRectMake(.5, .5, NSWidth([self bounds]) - 1, NSHeight([self bounds]) - 1);
    CGMutablePathRef path = CGPathCreateMutable();
    WBCGPathAddRoundRect(path, NULL, cgrect, 5);
    
    if (wb_saFlags.dark) {
      CGContextSetGrayStrokeColor(ctxt, 0.50, 0.60);
      CGContextSetGrayFillColor(ctxt, 0.65f, wb_saFlags.highlight ? .40f : .25f);
    } else {
      CGContextSetGrayStrokeColor(ctxt, 0.5, 1);
      CGContextSetGrayFillColor(ctxt, 0, wb_saFlags.highlight ? .15f : .08f);
    }
    
    /* Draw focus ring if needed */
    BOOL isFirst = wb_action && [[self window] firstResponder] == self;
    if (isFirst) {
      CGContextSaveGState(ctxt);
      /* Set focus ring */
      NSSetFocusRingStyle(NSFocusRingOnly);
      /* Fill invisible path */
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
      CGContextRestoreGState(ctxt);
    }
    
    CGContextAddPath(ctxt, path);
    CGContextStrokePath(ctxt);
    
    /* Draw before image if not highlight */
    if (!wb_saFlags.highlight) {
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
    }
    
    /* Draw icon */
    NSImage *icon = [self icon];
    if (icon) {
      NSRect source = NSZeroRect;
      source.size = [icon size];
      /* paint icon with y=3 (instead of 2) because lots of icon look better */
      CGFloat y = round((NSHeight([self bounds]) - kAVImageSize) / 2);
      [icon drawInRect:NSMakeRect(kAVMargin, y, kAVImageSize, kAVImageSize)
              fromRect:source
             operation:NSCompositeSourceOver
              fraction:1];
    }
    
    if (wb_saFlags.highlight) {
      CGContextAddPath(ctxt, path);
      CGContextFillPath(ctxt);
    }
    CGPathRelease(path);
    
    /* Draw string */
    if (!wb_saFlags.dark)
      CGContextSetShadowWithColor(ctxt, CGSizeMake(0, -1), 1, sShadowColor);
    
    CGFloat y = round((NSHeight([self bounds]) - kAVImageSize + 10) / 2);
    [[self title] drawAtPoint:NSMakePoint(kAVMargin + kAVImageSize + kAVImageRightMargin, y) withAttributes:nil];
  }
}

- (void)highlight:(BOOL)flag {
  bool previous = WBFlagTestAndSet(wb_saFlags.highlight, flag);
  if (previous != wb_saFlags.highlight) {
    [self setNeedsDisplay:YES];
  }
}

- (BOOL)mouseDownCanMoveWindow {
  return NO;
}

- (void)mouseClick:(NSEvent *)theEvent {
  if (wb_action)
    [NSApp sendAction:wb_action to:wb_target from:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
  /* No action, so don't need to handle event */
  if (!wb_action)
    return;
  
  BOOL keepOn = YES;
  
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  BOOL isInside = [self mouse:mouseLoc inRect:[self bounds]];
  
  if (isInside) {
    [self highlight:YES];
    
    while (keepOn) {
      theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
      mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
      isInside = [self mouse:mouseLoc inRect:[self bounds]];
      
      switch ([theEvent type]) {
        case NSLeftMouseDragged:
          [self highlight:isInside];
          break;
        case NSLeftMouseUp:
          if (isInside) [self mouseClick:theEvent];
          [self highlight:NO];
          keepOn = NO;
          break;
        default:
          /* Ignore any other kind of event. */
          break;
      }
    }
  }
}

- (void)keyDown:(NSEvent *)theEvent {
  if (!wb_action)
    return;
  
  NSString *chr = [theEvent characters];
  if ([chr length]) {
    switch ([chr characterAtIndex:0]) {
      case ' ':
      case '\r':
      case 0x03:
        [NSApp sendAction:wb_action to:wb_target from:self];
        return;
    }
  }
  [super keyDown:theEvent];
}

@end

@implementation WBImageAndTextView (NSAccessibility)

- (BOOL)accessibilityIsIgnored {
  return NO;
}

- (id)accessibilityHitTest:(NSPoint)point {
  return self;
}

- (id)accessibilityFocusedUIElement {
  return self;
}

- (NSArray *)accessibilityActionNames {
  return [NSArray arrayWithObject:NSAccessibilityPressAction];
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
  return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
  if ([action isEqualToString:NSAccessibilityPressAction]) {
    [self mouseClick:nil];
  } else {
    [super accessibilityPerformAction:action];
  }
}

- (NSArray *)accessibilityAttributeNames {
  NSMutableArray *attr = [[super accessibilityAttributeNames] mutableCopy];
  if (![attr containsObject:NSAccessibilityValueAttribute])
    [attr addObject:NSAccessibilityValueAttribute];
  if (![attr containsObject:NSAccessibilityEnabledAttribute])
    [attr addObject:NSAccessibilityEnabledAttribute];
  return [attr autorelease];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
  if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
    return NSAccessibilityButtonRole;
  else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute])
    return NSAccessibilityRoleDescription(NSAccessibilityButtonRole, nil);
  else if ([attribute isEqualToString:NSAccessibilityValueAttribute]) {
    return [self title];
  } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
    return WBBool(wb_action != NULL);
  }
  else return [super accessibilityAttributeValue:attribute];
}

@end

