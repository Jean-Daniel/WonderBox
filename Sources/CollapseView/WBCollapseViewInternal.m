//
//  WBCollapseViewInternal.m
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import "WBCollapseViewInternal.h"

#import WBHEADER(WBCollapseView.h)
#import WBHEADER(WBCollapseViewItem.h)

#import WBHEADER(WBCGFunctions.h)

#define ITEM_HEADER_HEIGHT 19
#define ITEM_BOTTOM_MARGIN 1 // bottom border (only when expanded)

@interface _WBCollapseItemView ()

- (void)wb_buildHeaderView;

- (void)wb_attachItem:(WBCollapseViewItem *)anItem;
- (void)wb_detachItem:(WBCollapseViewItem *)anItem;

@end

@implementation _WBCollapseItemView

@synthesize item = wb_item;

- (id)initWithItem:(WBCollapseViewItem *)anItem {
  NSParameterAssert(anItem && [anItem collapseView]);
  NSRect frame = NSMakeRect(0, 0, [[anItem collapseView] frame].size.width, ITEM_HEADER_HEIGHT);
  if (self = [super initWithFrame:frame]) {
    // setup self
    [self setAutoresizesSubviews:YES];
    
    wb_item = [anItem retain];

    [self wb_buildHeaderView];
    [self wb_attachItem:wb_item];
    
    // setup title
    [wb_title setStringValue:[wb_item title] ? : @""];
    
    // set initial state
    if ([wb_item isExpanded]) {
      CGFloat delta = [self expandHeight];
      if (delta > 0) {
        [self willSetExpanded:YES];
        // adjust frame
        frame.origin.y -= delta;
        frame.size.height += delta;
        [self setFrame:frame];
        [self didSetExpanded:YES];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [self wb_detachItem:wb_item];
  [wb_item release];
  [super dealloc];
}

#pragma mark -
// just to make it explicit
- (BOOL)isOpaque { return NO; }
- (BOOL)isFlipped { return NO; }

- (NSRect)headerBounds {
  NSRect frame = [self bounds];
  frame.origin.y = frame.size.height - ITEM_HEADER_HEIGHT;
  frame.size.height = ITEM_HEADER_HEIGHT;
  return frame;
}

- (CGFloat)expandHeight {
  return [wb_item view] ? NSHeight([[wb_item view] frame]) + ITEM_BOTTOM_MARGIN : 0;
}

- (id)identifier { return [wb_item identifier]; }
- (WBCollapseView *)collapseView { return [wb_item collapseView]; }

// MARK: Expension
- (void)willSetExpanded:(BOOL)expanded {
  if (XOR([wb_item isExpanded], expanded))
    [wb_item willSetExpanded:expanded];
  wb_civFlags.resizing = 1;
  if (expanded) {
    NSView *view = [wb_item view];
    if (view) {
      WBAssert(![view superview], @"why the item view is already in a view tree ?");
      
      wb_civFlags.resizeMask = [view autoresizingMask];
      [view setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
      
      // insert subview
      NSRect frame = [view frame];
      frame.size.width = NSWidth([self frame]);
      frame.origin = NSMakePoint(0, - NSHeight(frame));
      [view setFrame:frame];
      
      [self addSubview:view];
    }
  } else {
    
  }
  
}
- (void)didSetExpanded:(BOOL)expanded {
  [wb_disclose setState:expanded ? NSOnState : NSOffState];
  if (expanded) {
    
  } else {
    // remove child view
    [[wb_item view] removeFromSuperview];
    // restore resizing mask
    [[wb_item view] setAutoresizingMask:wb_civFlags.resizeMask];
  }
  wb_civFlags.resizing = 0;
  if (XOR([wb_item isExpanded], expanded))
    [wb_item didSetExpanded:expanded];
}

// MARK: Event Handling
- (void)mouseDown:(NSEvent *)theEvent {
  NSRect header = [self headerBounds];
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if (![self mouse:mouseLoc inRect:header]) return;
  
  // set is inside
  wb_civFlags.highlight = 1;
  //[wb_disclose setState:NSMixedState];
  [self setNeedsDisplayInRect:header];
  
  BOOL keepOn = YES;
  while (keepOn) {
    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    BOOL isInside = [self mouse:mouseLoc inRect:header] ? 1 : 0;
    
    switch ([theEvent type]) {
      case NSLeftMouseDragged:
        if (wb_civFlags.highlight != isInside) {
          wb_civFlags.highlight = isInside;
          //[wb_disclose setState:isInside ? NSMixedState : [wb_item isExpanded] ? NSOnState : NSOffState];
          [self setNeedsDisplayInRect:header];
        }
        break;
      case NSLeftMouseUp:
        if (isInside) {
          // toggle state
          [wb_item setExpanded:![wb_item isExpanded]];
          header = [self headerBounds];
        }
        wb_civFlags.highlight = 0;
        [self setNeedsDisplayInRect:header];
        keepOn = NO;
        break;
      default:
        /* Ignore any other kind of event. */
        break;
    }
  }
}

- (IBAction)toggleCollapse:(id)sender {
  [wb_item setExpanded:![wb_item isExpanded]];
}

// MARK: Model Sync
- (void)wb_attachItem:(WBCollapseViewItem *)anItem {
  [anItem addObserver:self forKeyPath:@"title" 
              options:0 context:_WBCollapseItemView.class];
  
  [anItem addObserver:self forKeyPath:@"view" 
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew 
              context:_WBCollapseItemView.class];  
}

- (void)wb_detachItem:(WBCollapseViewItem *)anItem {
  [anItem removeObserver:self forKeyPath:@"view"];
  [anItem removeObserver:self forKeyPath:@"title"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context != _WBCollapseItemView.class)
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  
  if ([keyPath isEqualToString:@"title"]) {
    // Update Title
    [wb_title setStringValue:[object title] ? : @""];
  } else if ([keyPath isEqualToString:@"view"]) {
    // adjust height and notify parent
    if (![wb_item isExpanded]) return;
    
    WBThrowException(NSInternalInconsistencyException, @"not implemented");
//		NSView *new = [change objectForKey:NSKeyValueChangeNewKey];    
//    NSView *old = [change objectForKey:NSKeyValueChangeOldKey];
//    CGFloat delta = new ? NSHeight([new frame]) : 0;
//    delta -= old ? NSHeight([old frame]) : 0;    
//    [old removeFromSuperview];
//    
//    delta = (new ? [new frame].size.height : 0) - delta;
//    
//    // adjust self size
//    if ([self isExpanded]) {
//      NSRect frame = [self frame];
//      frame.size.height += delta;
//      [self setFrame:frame];
//    }
//    
//    [self ed_configureItemView:new];
//    
//    // notify parent
//    if ([self isExpanded]) {
//      [self addSubview:new];
//      [[object collapseView] ed_didResizeItem:self delta:delta];
//    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

// MARK: -
// MARK: Drawing
- (void)drawRect:(NSRect)aRect {
  NSRect header = [self headerBounds];
  // redraw header if needed
  if (NSIntersectsRect(header, aRect))
    [self drawHeaderInRect:header];
  
  // draw bottom border if expanded
  if (wb_civFlags.resizing || [wb_item isExpanded]) {
    CGPoint line[2];
    NSRect bounds = [self bounds];
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth(ctxt, 1);
    
    line[0] = CGPointMake(NSMinX(bounds), NSMinY(bounds) + .5);
    line[1] = CGPointMake(NSMaxX(bounds), NSMinY(bounds) + .5);
    
    CGContextSetGrayStrokeColor(ctxt, .33, 1);
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

- (void)drawHeaderInRect:(NSRect)aRect {
  static CGLayerRef sHeaderBackground = NULL;
  
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  
  CGRect background = NSRectToCGRect(aRect);
  background.size.height -= 1;
  background.origin.y += 1;
  
  if (!sHeaderBackground) {
    WBCGSimpleShadingInfo info = {
      {.900, .900, .900, 1},
      {.733, .733, .733, 1},
      WBCGShadingSinFactorFunction,
    };
    sHeaderBackground = WBCGLayerCreateWithVerticalShading(ctxt, CGSizeMake(64, background.size.height), true, 
                                                           WBCGShadingSimpleShadingFunction, &info);
  }
  // draw background gradient
  CGContextDrawLayerInRect(ctxt, background, sHeaderBackground);
  
  // lazy highlighting
  if (wb_civFlags.highlight) {
    CGContextSetGrayFillColor(ctxt, 0, .25);
    CGContextFillRect(ctxt, background);
  }
  
  // draw bottom border
  CGContextSetLineWidth(ctxt, 1);
  {
    // first line
    CGContextSetGrayStrokeColor(ctxt, .33, 1);
    CGPoint line[] = {
      CGPointMake(NSMinX(aRect), NSMinY(aRect) + .5),
      CGPointMake(NSMaxX(aRect), NSMinY(aRect) + .5)
    };
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

// MARK: -
// MARK: Internal
- (void)wb_buildHeaderView {
  // Init Header Components
  NSRect buttonFrame, titleFrame = [self headerBounds];
  NSDivideRect(titleFrame, &buttonFrame, &titleFrame, 18, NSMinXEdge);
  
  // Text Field
  // empirical values
  titleFrame.origin.y += 3;
  titleFrame.size.height = 14; // mini label height
  
  wb_title = [[NSTextField alloc] initWithFrame:titleFrame];
  [wb_title setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
  [wb_title setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
  [[wb_title cell] setBackgroundStyle:NSBackgroundStyleRaised];
  [[wb_title cell] setControlSize:NSSmallControlSize];
  [wb_title setDrawsBackground:NO];
  [wb_title setSelectable:NO];
  [wb_title setBordered:NO];
  [self addSubview:wb_title];
  [wb_title release];
  
  // Disclose Button
  // Empirical values
  buttonFrame.origin.x += 4;
  buttonFrame.origin.y += 4;
  buttonFrame.size.height -= 4;
  
  wb_disclose = [[NSButton alloc] initWithFrame:buttonFrame];
  [wb_disclose setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
  [wb_disclose setBezelStyle:NSDisclosureBezelStyle];
  [wb_disclose setButtonType:NSOnOffButton];
  [wb_disclose setTitle:@""];
  [wb_disclose sizeToFit];
  // Setup action
  [wb_disclose setTarget:self];
  [wb_disclose setAction:@selector(toggleCollapse:)];
  // Add Button
  [self addSubview:wb_disclose];
  [wb_disclose release];
}

@end
