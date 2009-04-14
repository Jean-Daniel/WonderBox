//
//  WBCollapseViewItem.m
//  Emerald
//
//  Created by Jean-Daniel Dupas on 14/04/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import WBHEADER(WBCollapseViewItem.h)

#import "WBCollapseViewInternal.h"

@implementation WBCollapseViewItem

@synthesize view = wb_view;
@synthesize title = wb_title;

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:wb_view forKey:@"item.view"];
  [aCoder encodeObject:wb_title forKey:@"item.title"];
  [aCoder encodeObject:wb_uid forKey:@"item.identifier"];
  [aCoder encodeConditionalObject:wb_owner forKey:@"item.owner"];
  
  [aCoder encodeBool:wb_cviFlags.animates forKey:@"item.flags.animates"];
  [aCoder encodeBool:wb_cviFlags.expanded forKey:@"item.flags.expanded"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super init]) {
    wb_view = [[aCoder decodeObjectForKey:@"item.view"] retain];
    wb_title = [[aCoder decodeObjectForKey:@"item.title"] retain];
    wb_uid = [[aCoder decodeObjectForKey:@"item.identifier"] retain];
    wb_owner = [aCoder decodeObjectForKey:@"item.owner"];
    
    wb_cviFlags.animates = [aCoder decodeBoolForKey:@"item.flags.animates"];
    wb_cviFlags.expanded = [aCoder decodeBoolForKey:@"item.flags.expanded"];
  }
  return self;
}

- (id)initWithIdentifier:(id)anIdentifier {
  if (!anIdentifier) {
    [self release];
    WBThrowException(NSInvalidArgumentException,  @"identifier must not be nil");
  }
  
  if (self = [super init]) {
    wb_uid = anIdentifier;
    wb_cviFlags.animates = 1;
    wb_cviFlags.expanded = 1;
  }
  return self;
}

- (void)dealloc {
  [wb_title release];
  [wb_view release];
  [wb_uid release];
  [super dealloc];
}

#pragma mark -
- (id)identifier {
  return wb_uid;
}

- (WBCollapseView *)collapseView {
  return wb_owner;
}

- (void)setCollapseView:(WBCollapseView *)aView {
  wb_owner = aView;
}

- (BOOL)animates {
  return wb_cviFlags.animates;
}
- (void)setAnimates:(BOOL)aFlags {
  WBFlagSet(wb_cviFlags.animates, aFlags);
}

- (BOOL)isExpanded {
  return wb_cviFlags.expanded;
}

- (void)setExpanded:(BOOL)expanded {
  [self setExpanded:expanded animate:wb_cviFlags.animates];
}

- (void)setExpanded:(BOOL)expanded animate:(BOOL)flag {
  if (expanded && wb_cviFlags.expanded) return;
  if (!expanded && !wb_cviFlags.expanded) return;
  
  _WBCollapseItemView *view = [wb_owner _viewForItem:self];
  [view setExpanded:expanded animate:flag];
  WBFlagSet(wb_cviFlags.expanded, flag);
}

@end
