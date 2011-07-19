/*
 *  WBTabWindowController.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2010 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBTabWindowController.h)

@interface WBTabWindowController (NSToolbarDelegate)
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
<NSToolbarDelegate>
#endif

@end

@interface WBTabWindowItem ()

@property(nonatomic, copy) NSString *identifier;

@end

@implementation WBTabWindowController

+ (NSString *)nibName { return @"WBTabWindow"; }
// Force nib search in this bundle, even for subclasses
+ (NSBundle *)nibBundle { return [NSBundle bundleForClass:[WBTabWindowController class]]; }

- (void)dealloc {
  // nullify weak reference
  for (WBTabWindowItem *item in [wb_items allValues])
    item.tabWindow = nil;

  wb_release(wb_identifiers);
  wb_release(wb_classes);
  wb_release(wb_current);
  wb_release(wb_items);
  wb_dealloc();
}

#pragma mark -
- (NSArray *)classes { WBAbstractMethodException(); }
- (NSArray *)identifiers { WBAbstractMethodException(); }

- (NSString *)toolbarIdentifier {
  return [NSString stringWithFormat:@"%@.toolbar", [self class]];
}
- (NSString *)defaultTabWindowItem {
  return [wb_identifiers count] > 0 ? [wb_identifiers objectAtIndex:0] : nil;
}

- (void)wb_setup {
  // prepare item definition
  wb_identifiers = [[self identifiers] copyWithZone:[self zone]];
  NSArray *classes = [self classes];
  WBAssert([classes count] == [wb_identifiers count], @"inconsistent values");
  NSMutableDictionary *cache = [[NSMutableDictionary alloc] initWithCapacity:[wb_identifiers count]];
  for (NSUInteger idx = 0, count = [classes count]; idx < count; ++idx) {
    Class cls = [classes objectAtIndex:idx];
    WBAssert([cls isSubclassOfClass:[WBTabWindowItem class]], @"Invalid Item Class: %@", cls);
    [cache setObject:cls forKey:[wb_identifiers objectAtIndex:idx]];
  }
  wb_classes = cache;
}

- (void)windowDidLoad {
  [self wb_setup];

  wb_items = [[NSMutableDictionary alloc] init];

  NSToolbar *tb = [[NSToolbar alloc] initWithIdentifier:[self toolbarIdentifier]];
  [tb setDisplayMode:NSToolbarDisplayModeIconAndLabel];
  [tb setSizeMode:NSToolbarSizeModeRegular];
  [tb setAllowsUserCustomization:NO];
  [tb setShowsBaselineSeparator:YES];
  [tb setAutosavesConfiguration:NO];
  [tb setDelegate:self];
  [tb setVisible:YES];

  [[self window] setToolbar:tb];
  wb_release(tb);

  [self setSelectedItemIdentifier:[self defaultTabWindowItem]];
}

- (IBAction)selectPanel:(NSToolbarItem *)sender {
  [self setSelectedItemIdentifier:[sender itemIdentifier]];
}

- (NSString *)selectedItemIdentifier { return wb_current; }

- (void)selectItem:(WBTabWindowItem *)anItem {
  /* Setup view and insert it in the window */
  WBTabWindowItem *current = [self selectedItem];
  if (anItem == current) return; //noop

  [self willSelectItem:anItem];

  if (current) // remove current view from the window
    [[current view] removeFromSuperview];

  NSWindow *window = [self window]; // load window

  NSSize smin = [anItem minSize];
  NSSize smax = [anItem maxSize];

  NSView *itemView = [anItem view];
  NSSize s = [itemView frame].size; // get current size

  NSUInteger mask = [itemView autoresizingMask];
  if (0 == (mask & NSViewWidthSizable)) // fixed width
    smin.width = smax.width = s.width;

  if (0 == (mask & NSViewHeightSizable)) // fixed height
    smin.height = smax.height = s.height;

  // clamp current size
  if (s.width > smax.width)
    s.width = smax.width;
  else if (s.width < smin.width)
    s.width = smin.width;

  if (s.height > smax.height)
    s.height = smax.height;
  else if (s.height < smin.height)
    s.height = smin.height;

  // fixup size (if needed) and position
  [itemView setFrame:NSMakeRect(0, 0, s.width, s.height)];

  // We don't want to be constraint while resizing
  [window setContentMinSize:NSZeroSize];
  [window setContentMaxSize:NSMakeSize(10000, 10000)];

  [itemView setAutoresizingMask:0]; // fixed size until we finish resizing
  [[window contentView] addSubview:itemView];

  // Resize The Window to fit the target view
  NSRect frame = [window frame];
  NSRect wrect = [window frameRectForContentRect:NSMakeRect(0, 0, s.width, s.height)];

  frame.origin.y -= wrect.size.height - NSHeight(frame);
  frame.size = wrect.size;
  [window setFrame:frame display:YES animate:YES];

  // Fix windows size.
  [window setContentMinSize:smin];
  [window setContentMaxSize:smax];

  // view must only be width and height sizable.
  [window setShowsResizeIndicator:(mask & (NSViewWidthSizable | NSViewHeightSizable)) != 0];
  [itemView setAutoresizingMask:mask & (NSViewWidthSizable | NSViewHeightSizable)];


  /* Fixup responder chain */
  if (current)
    [anItem setNextResponder:[current nextResponder]];
  else
    [anItem setNextResponder:[self nextResponder]];
  [self setNextResponder:anItem];

  [[window toolbar] setSelectedItemIdentifier:anItem.identifier];
  wb_release(wb_current);
  wb_current = wb_retain(anItem.identifier);
  [self didSelectItem:anItem];
}

- (void)setSelectedItemIdentifier:(NSString *)aPanel {
  if (wb_current && [aPanel isEqual:wb_current]) return; // already selected

  Class cls = [wb_classes objectForKey:aPanel];
  if (!cls)
    WBThrowException(NSInvalidArgumentException, @"invalid panel identifier: %@", aPanel);

  WBTabWindowItem *item = [wb_items objectForKey:aPanel];
  if (!item) {
    // The panel was not loaded yet
    item = [[cls alloc] init];
    WBAssert(item, @"fail to create panel with identifier: %@", aPanel);
    [wb_items setObject:item forKey:aPanel];
    item.identifier = aPanel;
    item.tabWindow = self;
    wb_release(item);
  }
  [self selectItem:item];
}

- (void)setNextResponder:(NSResponder *)aResponder {
  WBTabWindowItem *panel = [self selectedItem];
  if (panel)
    [panel setNextResponder:aResponder];
  else
    [super setNextResponder:aResponder];
}

- (WBTabWindowItem *)selectedItem {
  NSString *current = [self selectedItemIdentifier];
  return current ? [wb_items objectForKey:current] : nil;
}

- (void)willSelectItem:(WBTabWindowItem *)anItem {}
- (void)didSelectItem:(WBTabWindowItem *)anItem {}

@end

@implementation WBTabWindowController (NSToolbarDelegate)

// MARK: Toolbar
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return wb_identifiers;
}
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return wb_identifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return wb_identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *item = nil;
  Class cls = [wb_classes objectForKey:itemIdentifier];

  if (cls) {
    item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setAction:@selector(selectPanel:)];
    [item setLabel:[cls label]];
    [item setImage:[cls image]];
    [item setTarget:self];
    (void)wb_autorelease(item);
  }

  return item;
}

@end

@implementation WBTabWindowItem

@synthesize tabWindow = wb_ctrl;
@synthesize identifier = wb_identifier;

+ (NSImage *)image { WBAbstractMethodException(); }
+ (NSString *)label { WBAbstractMethodException(); }

+ (NSString *)nibName { return NSStringFromClass(self); }

- (NSSize)minSize { return NSZeroSize; }
- (NSSize)maxSize { return NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX); }

- (id)init {
  if (self = [super initWithNibName:[[self class] nibName] bundle:nil]) {

  }
  return self;
}

- (void)dealloc {
  wb_release(wb_identifier);
  wb_dealloc();
}

- (void)loadView {
  [super loadView];
  [self viewDidLoad];
}

- (void)viewDidLoad {}

@end


