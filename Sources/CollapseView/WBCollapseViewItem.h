//
//  WBCollapseViewItem.h
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

@class WBCollapseView;
@interface WBCollapseViewItem : NSObject <NSCoding> {
@private
  id wb_uid;
  NSView *wb_view; // view to be displayed
  NSString *wb_title;
  WBCollapseView *wb_owner __weak; // back pointer to the parent view. Could be nil.
  struct _wb_cviFlags {
    unsigned int animates:1;
    unsigned int expanded:1;
    unsigned int reserved:6;
  } wb_cviFlags;
}

@property(retain) NSView *view;
@property(copy) NSString *title;

@property BOOL animates;

- (id)initWithIdentifier:(id)anIdentifier;

- (id)identifier;

- (WBCollapseView *)collapseView;

- (BOOL)isExpanded;
- (void)setExpanded:(BOOL)expanded; // animate:self.animates;
- (void)setExpanded:(BOOL)expanded animate:(BOOL)flag;

// Do not call directly
- (void)setCollapseView:(WBCollapseView *)aView;

@end
