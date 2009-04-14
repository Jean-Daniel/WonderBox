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
- (void)wb_setupItemView:(NSView *)aView;

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
    [self setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    
    wb_item = [anItem retain];

    [self wb_buildHeaderView];
    [self wb_attachItem:wb_item];
    [self wb_setupItemView:[wb_item view]];
    
    // setup title
    [wb_title setStringValue:[wb_item title] ? : @""];
    
    // set initial state
    if ([wb_item isExpanded]) 
      [self setExpanded:YES animate:NO];
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

- (NSRect)headerFrame {
  if ([wb_item isExpanded]) {
    NSRect frame = [self frame];
    frame.origin.y = frame.size.height - ITEM_HEADER_HEIGHT;
    frame.size.height = ITEM_HEADER_HEIGHT;
    return frame;
  }
  return [self frame];
}
- (NSRect)contentFrame {
  if ([wb_item isExpanded]) {
    NSRect frame = [self frame];
    // margin bottom: 1px
    frame.origin.y = ITEM_BOTTOM_MARGIN;
    frame.size.height -= ITEM_HEADER_HEIGHT + ITEM_BOTTOM_MARGIN;
    return frame;
  }
  return NSZeroRect;
}

- (id)identifier { return [wb_item identifier]; }
- (WBCollapseView *)collapseView { return [wb_item collapseView]; }

// MARK: Expension
- (void)setExpanded:(BOOL)expanded animate:(BOOL)flag {
  // TODO: 
  
  
  // Update Collapse Button State
  [wb_disclose setState:expanded ? NSOnState : NSOffState];
}

// MARK: Event Handling
- (void)mouseDown:(NSEvent *)theEvent {
  NSRect header = [self headerFrame];
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if (![self mouse:mouseLoc inRect:header]) return;
  
  // set is inside
  wb_civFlags.highlight = 1;
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
          [self setNeedsDisplayInRect:header];
        }
        break;
      case NSLeftMouseUp:
        if (isInside) {
          // toggle state
          [wb_item setExpanded:![wb_item isExpanded]];
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
    NSView *new = [change objectForKey:NSKeyValueChangeNewKey];
    
    [self wb_setupItemView:new];
    if (![wb_item isExpanded]) return;
    
    WBThrowException(NSInternalInconsistencyException, @"not implemented");
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
  NSRect header = [self headerFrame];
  // redraw header if needed
  if (NSIntersectsRect(header, aRect))
    [self drawHeaderInRect:header];
  
  // draw bottom border if expanded
  if ([wb_item isExpanded]) {
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
  CGContextSetGrayStrokeColor(ctxt, .33, 1);
  
  CGPoint line[] = {
    CGPointMake(NSMinX(aRect), NSMinY(aRect) + .5),
    CGPointMake(NSMaxX(aRect), NSMinY(aRect) + .5)
  };
  CGContextStrokeLineSegments(ctxt, line, 2);
}

// MARK: -
// MARK: Internal
- (void)wb_setupItemView:(NSView *)aView {
  if (!aView) return;
  
  // setup sizing mask to fit resizing behavior
  [aView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
  
  // adjust view width to fit self width
  NSRect frame = [aView frame];
  frame.size.width = NSWidth([self frame]);
  frame.origin = NSZeroPoint;
  
  [aView setFrame:frame];
}

- (void)wb_buildHeaderView {
  // Init Header Components
  NSRect buttonFrame, titleFrame = [self headerFrame];
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
