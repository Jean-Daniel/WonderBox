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

@implementation WBTabWindowController

+ (NSString *)nibName { return @"WBTabWindow"; }
// Force nib search in this bundle
+ (NSBundle *)nibBundle { return [NSBundle bundleForClass:WBTabWindowController.class]; }

- (void)dealloc {
  [wb_identifiers release];
  [wb_classes release];
  [wb_items release];
  [super dealloc];
}

#pragma mark -
- (NSArray *)classes { WBClusterException(); }
- (NSArray *)identifiers { WBClusterException(); }

- (NSString *)defaultTabWindowItem {
  return [wb_identifiers count] > 0 ? [wb_identifiers objectAtIndex:0] : nil;
}

- (void)wb_setup {
  // prepare item definition
  wb_identifiers = [[self identifiers] copyWithZone:[self zone]];
  NSArray *classes = [self classes];
  WBAssert([classes count] == [wb_identifiers count], @"inconsistent values");
  NSMutableDictionary *cache = [[NSMutableDictionary alloc] initWithCapacity:[wb_identifiers count]];
  for (NSUInteger idx = 0, count = [classes count]; idx < count; ++idx) 
    [cache setObject:[classes objectAtIndex:idx] forKey:[wb_identifiers objectAtIndex:idx]];
  wb_classes = cache;
}

- (void)windowDidLoad {
  WBAssert(uiMainView, @"broken binding");
  
  [self wb_setup];
  
  wb_items = [[NSMutableDictionary alloc] init];
  
  // FIXME: identifier should be exposed
  NSToolbar *tb = [[NSToolbar alloc] initWithIdentifier:@"preferences.toolbar"];
  [tb setDisplayMode:NSToolbarDisplayModeIconAndLabel];
  [tb setSizeMode:NSToolbarSizeModeRegular];
  [tb setAllowsUserCustomization:NO];
  [tb setShowsBaselineSeparator:YES];
  [tb setDelegate:self];
  [tb setVisible:YES];
  
  [[self window] setToolbar:tb];
  [tb release];
  
  [self setSelectedItem:[self defaultTabWindowItem]];
}

- (void)setDocument:(NSDocument *)document {
  [super setDocument:document];
  for (WBTabWindowItem *pane in [wb_items allValues])
    [pane setDocument:document];
}

- (IBAction)selectPanel:(NSToolbarItem *)sender {
  [self setSelectedItem:[sender itemIdentifier]];
}

- (NSString *)selectedItem {
  return [uiMainView selectedTabViewItem].identifier;
}

- (WBTabWindowItem *)selectedWindowPanel {
  NSString *uid = [self selectedItem];
  return uid ? [wb_items objectForKey:uid] : nil;
}

- (void)setSelectedItem:(NSString *)aPanel {
  // tb first, so it force load window
  NSToolbar *tb = [[self window] toolbar];
  Class cls = [wb_classes objectForKey:aPanel];
  if (!cls)
    WBThrowException(NSInvalidArgumentException, @"invalid panel identifier: %@", aPanel);
  
  NSUInteger idx = [uiMainView indexOfTabViewItemWithIdentifier:aPanel];
  if (NSNotFound == idx) {
    // The panel was not loaded yet
    WBTabWindowItem *pane = [[cls alloc] init];
    WBAssert(pane, @"fail to create panel with identifier: %@", aPanel);
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:aPanel];
    [item setView:[pane view]];
    
    [wb_items setObject:pane forKey:aPanel];
    [pane setDocument:self.document];
    [uiMainView addTabViewItem:item];
    
    [item release];
    [pane release];
    
    // refresh idx
    idx = [uiMainView indexOfTabViewItemWithIdentifier:aPanel];
  }
  
  WBTabWindowItem *current = [self selectedWindowPanel];
  WBTabWindowItem *target = [wb_items objectForKey:aPanel];
  if (current)
    [target setNextResponder:[current nextResponder]];
  else
    [target setNextResponder:[self nextResponder]];
  
  // Insert view controller in the responder chain
  [self setNextResponder:target];
  
  [tb setSelectedItemIdentifier:aPanel];
  [uiMainView selectTabViewItemAtIndex:idx];
}

- (void)setNextResponder:(NSResponder *)aResponder {
  WBTabWindowItem *panel = [self selectedWindowPanel];
  if (panel)
    [panel setNextResponder:aResponder];
  else
    [super setNextResponder:aResponder];
}

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
    [item autorelease];
  }
  
  return item;
}

@end

@implementation WBTabWindowItem

+ (NSImage *)image { WBClusterException(); }
+ (NSString *)label { WBClusterException(); }

+ (NSString *)nibName { return NSStringFromClass(self); }

- (id)init {
  if (self = [super initWithNibName:[[self class] nibName] bundle:nil]) {
    
  }
  return self;
}

- (void)loadView {
  [super loadView];
  [self viewDidLoad];
}

- (void)viewDidLoad {}
- (void)setDocument:(NSDocument *)aDocument { }

@end


