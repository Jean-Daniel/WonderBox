/*
 *  WBTabWindowController.h
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
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
