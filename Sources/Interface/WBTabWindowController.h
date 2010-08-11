/*
 *  WBTabWindowController.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2010 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBWindowController.h)

@class WBTabWindowItem;
@interface WBTabWindowController : WBWindowController {
@private
  /* Toolbar configuration */
  NSArray *wb_identifiers;
  NSDictionary *wb_classes;

  NSString *wb_current;
  NSMutableDictionary *wb_items;
}

@property(copy, nonatomic) NSString *selectedItemIdentifier;

// protected
- (NSArray *)classes; // abstract
- (NSArray *)identifiers; // abstract
- (NSString *)toolbarIdentifier;
- (NSString *)defaultTabWindowItem;

- (WBTabWindowItem *)selectedItem;

- (void)willSelectItem:(WBTabWindowItem *)anItem;
- (void)didSelectItem:(WBTabWindowItem *)anItem;

@end

@interface WBTabWindowItem : NSViewController {
@private
  NSString *wb_identifier;
  WBTabWindowController *wb_ctrl __weak;
}

@property(readonly, copy) NSString *identifier;
@property(assign) WBTabWindowController *tabWindow;

+ (NSImage *)image;
+ (NSString *)label;

- (NSSize)minSize;
- (NSSize)maxSize;

- (void)viewDidLoad;

@end