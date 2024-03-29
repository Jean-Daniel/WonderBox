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

#import <WonderBox/WBGradient.h>
#import <WonderBox/WBCGFunctions.h>
#import <WonderBox/WBCollapseView.h>
#import <WonderBox/WBCollapseViewItem.h>

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
  SEL wb_action;
  __unsafe_unretained id wb_target;

  NSTextField *wb_title;
  NSButton *wb_disclose;

  struct _wb_chvFlags {
    unsigned int highlight:1;
    unsigned int reserved:7;
  } wb_chvFlags;
}

@property(nonatomic) NSInteger state;
@property(nonatomic, copy) NSString *title;

@property(nonatomic) SEL action;
@property(nonatomic, assign) id target;

- (void)wb_performAction:(id)sender;

@end

@interface _WBCollapseItemBodyView : NSView {
@private
  uint8_t wb_flipped:1;
}

- (void)setFlipped:(BOOL)flag;

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
    wb_item = [aCoder decodeObjectForKey:@"view.item"];
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

    wb_item = anItem;

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
  if (spx_xor([wb_item isExpanded], expanded))
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

  wb_header.state = expanded ? NSControlStateValueOn : NSControlStateValueOff;
  if (expanded) {

  } else {
    // remove child view
    [wb_body setHidden:YES];
    [self wb_detachView:[wb_item view]];
  }
  wb_civFlags.resizing = 0;
  if (spx_xor([wb_item isExpanded], expanded))
    [wb_item didSetExpanded:expanded];
}

// MARK: Event Handling
- (IBAction)toggleCollapse:(id)sender {
  [wb_item setExpanded:![wb_item isExpanded]];
}

// MARK: Model Sync
- (void)wb_attachItem {
  NSAssert(wb_item, @"cannot attach nil item");

  [wb_item addObserver:self forKeyPath:@"title"
              options:0 context:(__bridge void *)[_WBCollapseItemView class]];

  [wb_item addObserver:self forKeyPath:@"view"
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
              context:(__bridge void *)[_WBCollapseItemView class]];
}

- (void)wb_detachItem {
  [wb_item removeObserver:self forKeyPath:@"view"];
  [wb_item removeObserver:self forKeyPath:@"title"];
  if ([wb_item isExpanded]) // restore state
    [self wb_detachView:[wb_item view]];

  wb_item = nil;
}

- (void)wb_attachView:(NSView *)theView {
  NSAssert(![theView superview], @"why the item view is already in a view tree ?");
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
  if (context != (__bridge void *)[_WBCollapseItemView class])
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

  if ([keyPath isEqualToString:@"title"]) {
    // Update Title
    wb_header.title = [object title];
  } else if ([keyPath isEqualToString:@"view"]) {
    // adjust height and notify parent
    if (![wb_item isExpanded]) return;

    SPXThrowException(NSInternalInconsistencyException, @"not implemented");
//    NSView *new = [change objectForKey:NSKeyValueChangeNewKey];
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

  NSAssert([aNotification object] == [wb_item view], @"notification object inconsistency");
  NSView *view = [wb_item view];
  NSRect frame = [view frame];

  if (fnotequal(NSWidth([self frame]), NSWidth(frame)))
    spx_log("#WARNING Changing item view width. This is not a good idea !");

  if (fnonzero(frame.origin.x)/* || fnotequal(frame.origin.y, ITEM_BOTTOM_MARGIN) */)
    spx_log("#WARNING Changing item origin. This is not a good idea !");

  // theorical item view height is body size - bottom margin (as the body origin is (0; 0))
  CGFloat height = NSHeight([wb_body frame]) - ITEM_BOTTOM_MARGIN;
  CGFloat delta = NSHeight(frame) - height;

  if (fnonzero(delta)) {// item height did change.
    /* Note about flipping .hack
     When resizing the item, it looks better when the top of the view is fixed.
     To do that with a non flipped view, we would have to adjust the view origin at each size change.
     By flipping the body view, we got the expected result automatically. There is a drawback though,
     as the content view origin is not (0, 0), but (0, ITEM_BOTTOM_MARGIN), we have to adjust it, as the flipped origin
     should be (0, ITEM_TOP_MARGIN), which is (0, 0).
     */
    wb_civFlags.resizing = 1; // must be set before we change the view origin
    [(_WBCollapseItemBodyView *)wb_body setFlipped:YES];
    [view setFrameOrigin:NSZeroPoint];
    [self.collapseView _resizeItemView:self delta:delta animate:[wb_item animates]];
    /* unflippe and restore origin */
    [(_WBCollapseItemBodyView *)wb_body setFlipped:NO];
    [view setFrameOrigin:NSMakePoint(0, ITEM_BOTTOM_MARGIN)];
    wb_civFlags.resizing = 0; // must be set after we change the view origin
  }
}

// MARK: -
// MARK: Internal
- (void)wb_buildBodyView {
  wb_body = [[_WBCollapseItemBodyView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth([self frame]), 0)];
  [wb_body setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [self addSubview:wb_body];
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
    [wb_title setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]]];
    [wb_title setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [[wb_title cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[wb_title cell] setControlSize:NSControlSizeSmall];
    [wb_title setDrawsBackground:NO];
    [wb_title setSelectable:NO];
    [wb_title setBordered:NO];
    [self addSubview:wb_title];

    // Disclose Button
    // Empirical values
    buttonFrame.origin.x += 4;
    buttonFrame.origin.y += 4;
    buttonFrame.size.height -= 4;

    wb_disclose = [[NSButton alloc] initWithFrame:buttonFrame];
    [wb_disclose setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [wb_disclose setBezelStyle:NSBezelStyleDisclosure];
    [wb_disclose setButtonType:NSButtonTypeOnOff];
    [wb_disclose setTitle:@""];
    [wb_disclose sizeToFit];
    // Setup action
    [wb_disclose setTarget:self];
    [wb_disclose setAction:@selector(wb_performAction:)];
    // Add Button
    [self addSubview:wb_disclose];
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
    theEvent = [[self window] nextEventMatchingMask: NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    BOOL isInside = [self mouse:mouseLoc inRect:bounds] ? 1 : 0;

    switch ([theEvent type]) {
      case NSEventTypeLeftMouseDragged:
        if (wb_chvFlags.highlight != (uint8_t)isInside) {
          SPXFlagSet(wb_chvFlags.highlight, isInside);
          //[wb_disclose setState:isInside ? NSMixedState : [wb_item isExpanded] ? NSOnState : NSOffState];
          [self setNeedsDisplayInRect:bounds];
        }
        break;
      case NSEventTypeLeftMouseUp:
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

static const
WBGradientDefinition sHeaderGradient = {
  kWBGradientColorSpace_RGB,
  WBInterpolationCallBackDef(WBInterpolationSin),
  {
    {
      1,
      WBGradientColorRGB(.700, .707, .777, 1), // 808
      WBGradientColorRGB(.926, .929, .973, 1), // 647
      kWBInterpolationDefault,
    },
  }
};

#define BORDER_WHITE .60

- (void)drawRect:(NSRect)aRect {
  static CGLayerRef sHeaderBackground = NULL;

  CGContextRef ctxt = [NSGraphicsContext currentGraphicsPort];
  NSRect bounds = [self bounds];
  CGRect background = NSRectToCGRect(bounds);
  background.size.height -= 1;
  background.origin.y += 1;

  if (!sHeaderBackground) {
    WBGradientBuilder *b = [[WBGradientBuilder alloc] initWithDefinition:&sHeaderGradient];
    sHeaderBackground = [b newLayerWithVerticalGradient:background.size.height context:ctxt];
  }
  // draw background gradient
  CGContextDrawLayerInRect(ctxt, background, sHeaderBackground);

  // lazy highlighting
  if (wb_chvFlags.highlight) {
    CGContextSetGrayFillColor(ctxt, 0, (CGFloat).25);
    CGContextFillRect(ctxt, background);
  }

  // draw bottom border
  CGContextSetLineWidth(ctxt, 1);
  {
    // first line
    CGContextSetGrayStrokeColor(ctxt, (CGFloat)BORDER_WHITE, 1);
    CGPoint line[] = {
      CGPointMake(NSMinX(bounds), NSMinY(bounds) + (CGFloat).5),
      CGPointMake(NSMaxX(bounds), NSMinY(bounds) + (CGFloat).5)
    };
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

@end

@implementation _WBCollapseItemBodyView

- (BOOL)isFlipped { return (BOOL)wb_flipped; }
- (void)setFlipped:(BOOL)flag { SPXFlagSet(wb_flipped, flag); }

- (void)drawRect:(NSRect)aRect {
  CGPoint line[2];
  NSRect bounds = [self bounds];
  CGContextRef ctxt = [NSGraphicsContext currentGraphicsPort];
  CGContextSetGrayFillColor(ctxt, .91, 1);
  CGContextFillRect(ctxt, NSRectToCGRect(aRect));

  if (NSIntersectsRect(bounds, aRect)) {
    CGContextSetLineWidth(ctxt, 1);

    CGFloat y = [self isFlipped] ? NSMaxY(bounds) - (CGFloat).5 : NSMinY(bounds) + (CGFloat).5;
    line[0] = CGPointMake(NSMinX(bounds), y);
    line[1] = CGPointMake(NSMaxX(bounds), y);

    CGContextSetGrayStrokeColor(ctxt, (CGFloat)BORDER_WHITE, 1);
    CGContextStrokeLineSegments(ctxt, line, 2);
  }
}

@end

