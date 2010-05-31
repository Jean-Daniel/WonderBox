/*
 *  WBCollapseViewItem.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBCollapseViewItem.h)

#import "WBCollapseViewInternal.h"

@implementation WBCollapseViewItem

@synthesize view = wb_view;
@synthesize title = wb_title;
@synthesize identifier = wb_uid;

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

- (id)init {
  return [self initWithView:nil identifier:nil];
}
- (id)initWithView:(NSView *)aView {
  return [self initWithView:aView identifier:nil];
}
- (id)initWithView:(NSView *)aView identifier:(id)anIdentifier {
  if (self = [super init]) {
    self.view = aView;
    wb_cviFlags.animates = 1;
    wb_cviFlags.expanded = 1;
    self.identifier = anIdentifier;
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

  if (wb_owner)
    [wb_owner _setExpanded:expanded forItem:self animate:flag];
  else
    WBFlagSet(wb_cviFlags.expanded, expanded);
}

@end

@implementation WBCollapseViewItem (WBInternal)

- (void)willSetExpanded:(BOOL)expanded {}
- (void)didSetExpanded:(BOOL)expanded {
  WBFlagSet(wb_cviFlags.expanded, expanded);
}

@end

