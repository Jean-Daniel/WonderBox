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
#import WBHEADER(WBGeometry.h)
#import WBHEADER(WBCollapseView.h)
#import WBHEADER(WBCollapseViewItem.h)

#define ITEM_HEADER_HEIGHT 19
#define ITEM_BOTTOM_MARGIN 1 // bottom border (only when expanded)

@interface _WBCollapseItemView ()

- (void)wb_buildBodyView;
- (void)wb_buildHeaderView;

- (void)wb_attachItem;
- (void)wb_detachItem;

- (void)wb_attachView:(NSView *)theView;
- (void)wb_detachView:(NSView *)theView;

- (void)_didChangeItemFrame:(NSNotification *)aNotification;

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

- (void)wb_performAction:(id)sender;

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
    [self wb_attachItem];
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

    [self wb_attachItem];
    [self wb_buildBodyView];
    [self wb_buildHeaderView];


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
  [self wb_detachItem];
  [super dealloc];
}

#pragma mark -
// just to make it explicit
- (BOOL)isOpaque { return NO; }
- (BOOL)isFlipped { return NO; }

- (CGFloat)expandHeight {
  return [wb_item view] ? NSHeight([[wb_item view] frame]) + ITEM_BOTTOM_MARGIN : 0;
}

- (id)identifier { return [wb_item identifier]; }
- (void)invalidate { [self wb_detachItem]; }
- (WBCollapseView *)collapseView { return [wb_item collapseView]; }

// MARK: Expension
- (void)willSetExpanded:(BOOL)expanded {
  // notify only if state change, but continue even if state do not change (to refresh the view).
  if (XOR([wb_item isExpanded], expanded))
    [wb_item willSetExpanded:expanded];
  wb_civFlags.resizing = 1;
  if (expanded) {
    if ([wb_item view]) {
      // Add subview
      [self wb_attachView:[wb_item view]];
      [wb_body setHidden:NO];
    }
  } else {
    // will collapse

  }
  // temporary disabled notifications while resizing
  [[wb_item view] setPostsFrameChangedNotifications:NO];
}
- (void)didSetExpanded:(BOOL)expanded {
  // Restore notification state
  [[wb_item view] setPostsFrameChangedNotifications:YES];

  wb_header.state = expanded ? NSOnState : NSOffState;
  if (expanded) {

  } else {
    // remove child view
    [wb_body setHidden:YES];
    [self wb_detachView:[wb_item view]];
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
- (void)wb_attachItem {
  WBAssert(wb_item, @"cannot attach nil item");

  [wb_item addObserver:self forKeyPath:@"title"
              options:0 context:_WBCollapseItemView.class];

  [wb_item addObserver:self forKeyPath:@"view"
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
              context:_WBCollapseItemView.class];
}

- (void)wb_detachItem {
  [wb_item removeObserver:self forKeyPath:@"view"];
  [wb_item removeObserver:self forKeyPath:@"title"];
  if ([wb_item isExpanded]) // restore state
    [self wb_detachView:[wb_item view]];

  [wb_item release];
  wb_item = nil;
}

- (void)wb_attachView:(NSView *)theView {
  WBAssert(![theView superview], @"why the item view is already in a view tree ?");
  // resizing mask
  wb_civFlags.resizeMask = (uint32_t)[theView autoresizingMask];
  if (wb_civFlags.resizeMask != (NSViewWidthSizable | NSViewMaxYMargin))
    [theView setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];

  // frame change notification
  wb_civFlags.posts = [[wb_item view] postsFrameChangedNotifications] ? 1 : 0;
  if (!wb_civFlags.posts)
    [theView setPostsFrameChangedNotifications:YES];

  // insert subview
  NSRect frame = [theView frame];
  frame.size.width = NSWidth([self frame]);
  frame.origin = NSMakePoint(0, ITEM_BOTTOM_MARGIN);
  [theView setFrame:frame];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didChangeItemFrame:)
                                               name:NSViewFrameDidChangeNotification
                                             object:theView];
  [wb_body addSubview:theView];
}

- (void)wb_detachView:(NSView *)theView {
  [theView removeFromSuperview];
  [theView setAutoresizingMask:wb_civFlags.resizeMask];
  [theView setPostsFrameChangedNotifications:wb_civFlags.posts];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:theView];
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

- (void)_didChangeItemFrame:(NSNotification *)aNotification {
  if (wb_civFlags.resizing) return;

  WBAssert([aNotification object] == [wb_item view], @"notification object inconsistency");
  NSView *view = [wb_item view];
  NSRect frame = [view frame];

  if (fnotequal(NSWidth([self frame]), NSWidth(frame)))
    WBLogWarning(@"Changing item view width. This is not a good idea !");

  if (fnonzero(frame.origin.x) || fnotequal(frame.origin.y, ITEM_BOTTOM_MARGIN))
    WBLogWarning(@"Changing item origin. This is not a good idea !");

  // theorical item view height is body size - bottom margin (as the body origin is (0; 0))
  CGFloat height = NSHeight([wb_body frame]) - ITEM_BOTTOM_MARGIN;
  CGFloat delta = NSHeight(frame) - height;

  if (fnonzero(delta)) {// item height did change.
    wb_civFlags.resizing = 1;
    [self.collapseView _resizeItemView:self delta:delta animate:[wb_item animates]];
    wb_civFlags.resizing = 0;
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
  NSRect frame = [self bounds];
  frame.origin.y = frame.size.height - ITEM_HEADER_HEIGHT;
  frame.size.height = ITEM_HEADER_HEIGHT;

  wb_header = [[_WBCollapseItemHeaderView alloc] initWithFrame:frame];
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
        if (wb_chvFlags.highlight != (uint8_t)isInside) {
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

  CGContextRef ctxt = [NSGraphicsContext currentGraphicsPort];
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
    CGContextRef ctxt = [NSGraphicsContext currentGraphicsPort];
    CGContextSetLineWidth(ctxt, 1);

    line[0] = CGPointMake(NSMinX(bounds), NSMinY(bounds) + .5);
    line[1] = CGPointMake(NSMaxX(bounds), NSMinY(bounds) + .5);

    CGContextSetGrayStrokeColor(ctxt, .33, 1);
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

@end

