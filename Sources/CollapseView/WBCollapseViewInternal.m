/*
 *  WBCollapseViewInternal.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBCollapseViewInternal.h"

#import WBHEADER(WBGradient.h)
#import WBHEADER(WBCollapseView.h)
#import WBHEADER(WBCollapseViewItem.h)

#define ITEM_HEADER_HEIGHT 19
#define ITEM_BOTTOM_MARGIN 1 // bottom border (only when expanded)

@interface _WBCollapseItemView ()

- (void)wb_buildBodyView;
- (void)wb_buildHeaderView;

- (void)wb_attachItem:(WBCollapseViewItem *)anItem;
- (void)wb_detachItem:(WBCollapseViewItem *)anItem;

@end

@interface _WBCollapseItemHeaderView : NSView {
@private
  id wb_target;
  SEL wb_action;
  
  NSTextField *wb_title;
  NSButton *wb_disclose;
  
  struct _wb_chvFlags {
    unsigned int highlight:1;
    unsigned int reserved:7;
  } wb_chvFlags;
}

@property NSInteger state;
@property(copy) NSString *title;

@property SEL action;
@property(assign) id target;

@end

@interface _WBCollapseItemBodyView : NSView {
  
}


@end

@implementation _WBCollapseItemView

@synthesize item = wb_item;

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:wb_item forKey:@"view.item"];
  [aCoder encodeObject:wb_body forKey:@"view.body"];
  [aCoder encodeObject:wb_header forKey:@"view.header"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    wb_item = [[aCoder decodeObjectForKey:@"view.item"] retain];
    [self wb_attachItem:wb_item];
    wb_body = [aCoder decodeObjectForKey:@"view.body"];
    wb_header = [aCoder decodeObjectForKey:@"view.header"];
  }
  return self;
}

- (id)initWithItem:(WBCollapseViewItem *)anItem {
  NSParameterAssert(anItem && [anItem collapseView]);
  NSRect frame = NSMakeRect(0, 0, [[anItem collapseView] frame].size.width, ITEM_HEADER_HEIGHT);
  if (self = [super initWithFrame:frame]) {
    // setup self
    [self setAutoresizesSubviews:YES];
    
    wb_item = [anItem retain];

    [self wb_buildBodyView];
    [self wb_buildHeaderView];
    [self wb_attachItem:wb_item];
    
    // setup title
    wb_header.title = [wb_item title];
    
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

- (NSRect)headerFrame {
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
  // notify only if state change, but continue even if state do not change (to refresh the view).
  if (XOR([wb_item isExpanded], expanded))
    [wb_item willSetExpanded:expanded];
  wb_civFlags.resizing = 1;
  if (expanded) {
    NSView *view = [wb_item view];
    if (view) {
      WBAssert(![view superview], @"why the item view is already in a view tree ?");
      
      wb_civFlags.resizeMask = [view autoresizingMask];
      [view setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
      
      // insert subview
      NSRect frame = [view frame];
      frame.size.width = NSWidth([self frame]);
      frame.origin = NSMakePoint(0, 0);
      [view setFrame:frame];
      
      [wb_body addSubview:view];
      [wb_body setHidden:NO];
    }
  } else {
    // will collapse
    
  }
}
- (void)didSetExpanded:(BOOL)expanded {
  wb_header.state = expanded ? NSOnState : NSOffState;
  if (expanded) {
    
  } else {
    [wb_body setHidden:YES];
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
    wb_header.title = [object title];
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
// MARK: Internal
- (void)wb_buildBodyView {
  wb_body = [[_WBCollapseItemBodyView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth([self frame]), 0)];
  [wb_body setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [self addSubview:wb_body];
  [wb_body release];
}

- (void)wb_buildHeaderView {
  // Init Header Components
  wb_header = [[_WBCollapseItemHeaderView alloc] initWithFrame:[self headerFrame]];
  [wb_header setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
  wb_header.target = self;
  wb_header.action = @selector(toggleCollapse:);
  [self addSubview:wb_header];
  [wb_header release];
}

@end

@implementation _WBCollapseItemHeaderView

@synthesize target = wb_target;
@synthesize action = wb_action;

- (id)initWithFrame:(NSRect)aRect {
  if (self = [super initWithFrame:aRect]) {
    NSRect buttonFrame, titleFrame = NSMakeRect(0, 0, NSWidth(aRect), NSHeight(aRect));
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
    [wb_disclose setAction:@selector(wb_performAction:)];
    // Add Button
    [self addSubview:wb_disclose];
    [wb_disclose release];
  }
  return self;
}

- (BOOL)isOpaque { return YES; }
- (BOOL)isFlipped { return NO; }

- (void)wb_performAction:(id)sender {
  [NSApp sendAction:wb_action to:wb_target from:self];
}

- (NSInteger)state { return [wb_disclose state]; }
- (void)setState:(NSInteger)aState { [wb_disclose setState:aState]; }

- (NSString *)title { return [wb_title stringValue]; }
- (void)setTitle:(NSString *)aTitle { [wb_title setStringValue:aTitle ? : @""]; }

- (void)mouseDown:(NSEvent *)theEvent {
  NSRect bounds = [self bounds];
  NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if (![self mouse:mouseLoc inRect:bounds]) 
    return [super mouseDown:theEvent];
  
  // set is inside
  wb_chvFlags.highlight = 1;
  //[wb_disclose setState:NSMixedState];
  [self setNeedsDisplayInRect:bounds];
  
  BOOL keepOn = YES;
  while (keepOn) {
    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    BOOL isInside = [self mouse:mouseLoc inRect:bounds] ? 1 : 0;
    
    switch ([theEvent type]) {
      case NSLeftMouseDragged:
        if (wb_chvFlags.highlight != isInside) {
          wb_chvFlags.highlight = isInside;
          //[wb_disclose setState:isInside ? NSMixedState : [wb_item isExpanded] ? NSOnState : NSOffState];
          [self setNeedsDisplayInRect:bounds];
        }
        break;
      case NSLeftMouseUp:
        if (isInside) {
          // toggle state
          [self wb_performAction:nil];
          bounds = [self bounds];
        }
        wb_chvFlags.highlight = 0;
        [self setNeedsDisplayInRect:bounds];
        keepOn = NO;
        break;
      default:
        /* Ignore any other kind of event. */
        break;
    }
  }
}

- (void)drawRect:(NSRect)aRect {
  static CGLayerRef sHeaderBackground = NULL;
  
  CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
  NSRect bounds = [self bounds];
  CGRect background = NSRectToCGRect(bounds);
  background.size.height -= 1;
  background.origin.y += 1;
  
  if (!sHeaderBackground) {
    WBGradientBuilder *b = [[WBGradientBuilder alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:.733 alpha:1]
                                                                endingColor:[NSColor colorWithCalibratedWhite:.9 alpha:1]];
    sHeaderBackground = [b newLayerWithVerticalGradient:CGSizeMake(64, background.size.height) scale:true context:ctxt];
    [b release];
  }
  // draw background gradient
  CGContextDrawLayerInRect(ctxt, background, sHeaderBackground);
  
  // lazy highlighting
  if (wb_chvFlags.highlight) {
    CGContextSetGrayFillColor(ctxt, 0, .25);
    CGContextFillRect(ctxt, background);
  }
  
  // draw bottom border
  CGContextSetLineWidth(ctxt, 1);
  {
    // first line
    CGContextSetGrayStrokeColor(ctxt, .33, 1);
    CGPoint line[] = {
      CGPointMake(NSMinX(bounds), NSMinY(bounds) + .5),
      CGPointMake(NSMaxX(bounds), NSMinY(bounds) + .5)
    };
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

@end

@implementation _WBCollapseItemBodyView

- (void)drawRect:(NSRect)aRect {
  CGPoint line[2];
  NSRect bounds = [self bounds];
  if (NSIntersectsRect(bounds, aRect)) {
    CGContextRef ctxt = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetLineWidth(ctxt, 1);
    
    line[0] = CGPointMake(NSMinX(bounds), NSMinY(bounds) + .5);
    line[1] = CGPointMake(NSMaxX(bounds), NSMinY(bounds) + .5);
    
    CGContextSetGrayStrokeColor(ctxt, .33, 1);
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

@end

