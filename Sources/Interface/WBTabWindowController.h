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

@interface WBTabWindowController : WBWindowController {
@private
  /* Toolbar configuration */
  NSArray *wb_identifiers;
  NSDictionary *wb_classes;
  /* Tab View Manager */
  IBOutlet NSTabView *uiMainView;
  NSMutableDictionary *wb_items;
}

@property(copy, nonatomic) NSString *selectedItem;

// protected
- (NSArray *)classes; // abstract
- (NSArray *)identifiers; // abstract
- (NSString *)defaultTabWindowItem;

@end

@interface WBTabWindowItem : NSViewController {
@private
  
}

+ (NSImage *)image;
+ (NSString *)label;

- (void)viewDidLoad;
- (void)setDocument:(NSDocument *)aDocument;

@end
