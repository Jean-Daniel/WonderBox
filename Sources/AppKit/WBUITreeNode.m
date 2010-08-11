/*
 *  WBUITreeNode.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBUITreeNode.h)

NSString * const WBNewChildren = @"WBNewChildren";
NSString * const WBRemovedChild = @"WBRemovedChild";
NSString * const WBInsertedChild = @"WBInsertedChild";

/* Notification */
NSString * const WBUITreeNodeWillChangeNameNotification = @"WBUITreeNodeWillChangeName";
NSString * const WBUITreeNodeDidChangeNameNotification = @"WBUITreeNodeDidChangeName";

NSString * const WBUITreeNodeWillInsertChildNotification = @"WBUITreeNodeWillInsertChild";
NSString * const WBUITreeNodeDidInsertChildNotification = @"WBUITreeNodeDidInsertChild";

NSString * const WBUITreeNodeWillRemoveChildNotification = @"WBUITreeNodeWillRemoveChild";
NSString * const WBUITreeNodeDidRemoveChildNotification = @"WBUITreeNodeDidRemoveChild";

NSString * const WBUITreeNodeWillReplaceChildNotification = @"WBUITreeNodeWillReplaceChild";
NSString * const WBUITreeNodeDidReplaceChildNotification = @"WBUITreeNodeDidReplaceChild";

NSString * const WBUITreeNodeWillSetChildrenNotification = @"WBUITreeNodeWillSetChildren";
NSString * const WBUITreeNodeDidSetChildrenNotification = @"WBUITreeNodeDidSetChildren";

NSString * const WBUITreeNodeWillSortChildrenNotification = @"WBUITreeNodeWillSortChildren";
NSString * const WBUITreeNodeDidSortChildrenNotification = @"WBUITreeNodeDidSortChildren";

@implementation WBUITreeNode

#pragma mark Protocols Implementations
- (id)copyWithZone:(NSZone *)aZone {
  WBUITreeNode *copy = [super copyWithZone:aZone];
  copy->wb_name = [wb_name copyWithZone:aZone];
  copy->wb_icon = [wb_icon copyWithZone:aZone];
  return copy;
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    wb_name = [[aCoder decodeObjectForKey:@"SUName"] retain];
    wb_icon = [[aCoder decodeObjectForKey:@"SUIcon"] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:wb_icon forKey:@"SUIcon"];
  [aCoder encodeObject:wb_name forKey:@"SUName"];
}

#pragma mark -
- (void)dealloc {
  [wb_icon release];
  [wb_name release];
  [super dealloc];
}

#pragma mark -
- (NSImage *)icon {
  return wb_icon;
}
- (void)wb_setIcon:(NSImage *)anIcon {
  WBSetterRetain(wb_icon, anIcon);
}

- (NSString *)name {
  return wb_name;
}
- (void)wb_setName:(NSString *)aName {
  WBSetterCopy(wb_name, aName);
}

@end

#pragma mark -
@implementation WBBaseUITreeNode

+ (void)initialize {
  if (self == WBUITreeNode.class) {
    [self exposeBinding:@"icon"];
    [self exposeBinding:@"name"];
  }
}

#pragma mark Protocols Implementations
- (id)copyWithZone:(NSZone *)aZone {
  WBBaseUITreeNode *copy = [super copyWithZone:aZone];
  copy->wb_utFlags = wb_utFlags;
  return copy;
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    /* to avoid endian and bit fields problems */
    UInt32 flags = [aCoder decodeInt32ForKey:@"SUFlags"];
    WBFlagSet(wb_utFlags.leaf, flags & 0x01);
    WBFlagSet(wb_utFlags.undo, flags & 0x02);
    WBFlagSet(wb_utFlags.notify, flags & 0x04);
    WBFlagSet(wb_utFlags.editable, flags & 0x08);
    WBFlagSet(wb_utFlags.removable, flags & 0x10);
    WBFlagSet(wb_utFlags.draggable, flags & 0x20);
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  /* to avoid endian and bit fields problems */
  UInt32 flags = 0;
  if (wb_utFlags.leaf) flags |= 0x01;
  if (wb_utFlags.undo) flags |= 0x02;
  if (wb_utFlags.notify) flags |= 0x04;
  if (wb_utFlags.editable) flags |= 0x08;
  if (wb_utFlags.removable) flags |= 0x10;
  if (wb_utFlags.draggable) flags |= 0x20;
  [aCoder encodeInt32:flags forKey:@"SUFlags"];
}

#pragma mark Initializer
+ (id)nodeWithName:(NSString *)aName {
  return [[[self alloc] initWithName:aName icon:nil] autorelease];
}

+ (id)nodeWithName:(NSString *)aName icon:(NSImage *)anIcon {
  return [[[self alloc] initWithName:aName icon:anIcon] autorelease];
}

- (id)init {
  return [self initWithName:nil icon:nil];
}

- (id)initWithName:(NSString *)aName {
  return [self initWithName:aName icon:nil];
}

- (id)initWithName:(NSString *)aName icon:(NSImage *)anIcon {
  if (self = [super init]) {
    [self setName:aName];
    [self setIcon:anIcon];
  }
  return self;
}

#pragma mark -
#pragma mark Undo
- (BOOL)registerUndo {
  return wb_utFlags.undo;
}
- (void)setRegisterUndo:(BOOL)flag {
  WBFlagSet(wb_utFlags.undo, flag);
}
- (NSUndoManager *)undoManager {
  return [[self parent] undoManager];
}

#pragma mark Notify
- (BOOL)notify {
  return wb_utFlags.notify;
}
- (void)setNotify:(BOOL)notify {
  WBFlagSet(wb_utFlags.notify, notify);
}
- (NSNotificationCenter *)notificationCenter {
  return [[self parent] notificationCenter];
}

#pragma mark Node Properties
- (BOOL)isLeaf {
  return wb_utFlags.leaf;
}
- (void)setIsLeaf:(BOOL)flag {
  WBFlagSet(wb_utFlags.leaf, flag);
}

- (BOOL)isEditable {
  return wb_utFlags.editable;
}
- (void)setEditable:(BOOL)flag {
  WBFlagSet(wb_utFlags.editable, flag);
}

- (BOOL)isRemovable {
  return wb_utFlags.removable;
}
- (void)setRemovable:(BOOL)flag {
  WBFlagSet(wb_utFlags.removable, flag);
}

- (BOOL)isDraggable {
  return wb_utFlags.draggable;
}
- (void)setDraggable:(BOOL)flag {
  WBFlagSet(wb_utFlags.draggable, flag);
}

- (BOOL)isCollapsable {
  return !wb_utFlags.uncollapsable;
}
- (void)setCollapsable:(BOOL)flag {
  WBFlagSet(wb_utFlags.uncollapsable, !flag);
}

- (BOOL)isGroupNode {
  return wb_utFlags.group;
}
- (void)setIsGroupNode:(BOOL)flag {
  WBFlagSet(wb_utFlags.group, flag);
}

#pragma mark Name & Icon
- (void)sortByName {
  static NSArray *sSorts = nil;
  if (!sSorts) {
    NSSortDescriptor *name = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    sSorts = [[NSArray alloc] initWithObjects:name, nil];
    [name release];
  }
  [self sortUsingDescriptors:sSorts];
}

- (void)setIcon:(NSImage *)newIcon {
  NSImage *previous = [self icon];
  if (newIcon != previous) {
    if ([self registerUndo]) {
      [[self undoManager] registerUndoWithTarget:self selector:_cmd object:previous];
    }
    [self willChangeValueForKey:@"representation"];
    [self wb_setIcon:newIcon];
    [self didChangeValueForKey:@"representation"];
  }
}

- (void)setName:(NSString *)newName {
  if (newName != [self name]) {
    if ([self registerUndo]) {
      [[self undoManager] registerUndoWithTarget:self selector:_cmd object:[self name]];
    }
    if ([self notify]) {
      [[self notificationCenter] postNotificationName:WBUITreeNodeWillChangeNameNotification object:self];
    }
    [self willChangeValueForKey:@"representation"];
    [self wb_setName:newName];
    if ([self notify]) {
      [[self notificationCenter] postNotificationName:WBUITreeNodeDidChangeNameNotification object:self];
    }
    [self didChangeValueForKey:@"representation"];
  }
}

- (NSImage *)icon { return nil; }
- (void)wb_setIcon:(NSImage *)anIcon { }

- (NSString *)name { return nil; }
- (void)wb_setName:(NSString *)aName { }

- (id)representation { return self; }
- (void)setRepresentation:(NSString *)aName { [self setName:aName]; }

#pragma mark -
#pragma mark Notifications
/*
 - (void)prependChild:(WBTreeNode *)child {
 }
 - (void)appendChild:(WBTreeNode *)child {
 }
 - (void)insertChild:(WBTreeNode *)newChild atIndex:(NSUInteger)index {
 }
 */

- (void)performOperation:(WBTreeOperation)op atIndex:(NSUInteger)anIndex withChild:(WBTreeNode *)child {
  switch (op) {
    case kWBTreeOperationInsert:
    case kWBTreeOperationAppend: {
      if (wb_utFlags.undo) {
        [[self undoManager] registerUndoWithTarget:child selector:@selector(remove) object:nil];
      }
      NSDictionary *info = nil;
      if (wb_utFlags.notify) {
        info = [NSDictionary dictionaryWithObject:child forKey:WBInsertedChild];
        [[self notificationCenter] postNotificationName:WBUITreeNodeWillInsertChildNotification
                                                 object:self
                                               userInfo:info];
      }
      [super performOperation:op atIndex:anIndex withChild:child];
      if (wb_utFlags.notify) {
        [[self notificationCenter] postNotificationName:WBUITreeNodeDidInsertChildNotification
                                                 object:self
                                               userInfo:info];
      }
    }
      break;
    default:
      [super performOperation:op atIndex:anIndex withChild:child];
      break;
  }
}

- (void)replaceChildAtIndex:(NSUInteger)anIndex withChild:(WBTreeNode *)child {
  if (wb_utFlags.undo) {
    [[[self undoManager] prepareWithInvocationTarget:self] replaceChildAtIndex:anIndex withChild:[self childAtIndex:anIndex]];
  }
  NSDictionary *info = nil;
  if (wb_utFlags.notify) {
    info = [NSDictionary dictionaryWithObjectsAndKeys:
      child, WBInsertedChild,
      [self childAtIndex:anIndex], WBRemovedChild, nil];
    [[self notificationCenter] postNotificationName:WBUITreeNodeWillReplaceChildNotification
                                             object:self
                                           userInfo:info];
  }
  [super replaceChildAtIndex:anIndex withChild:child];
  if (wb_utFlags.notify) {
    [[self notificationCenter] postNotificationName:WBUITreeNodeDidReplaceChildNotification
                                             object:self
                                           userInfo:info];
  }
}

- (void)removeChildAtIndex:(NSUInteger)anIndex {
  if (wb_utFlags.undo) {
    [[[self undoManager] prepareWithInvocationTarget:self] insertChild:[self childAtIndex:anIndex] atIndex:anIndex];
  }
  NSDictionary *info = nil;
  if (wb_utFlags.notify) {
    info = [NSDictionary dictionaryWithObjectsAndKeys:
      [self childAtIndex:anIndex], WBRemovedChild, nil];
    [[self notificationCenter] postNotificationName:WBUITreeNodeWillRemoveChildNotification
                                             object:self
                                           userInfo:info];
  }
  [super removeChildAtIndex:anIndex];
  if (wb_utFlags.notify) {
    [[self notificationCenter] postNotificationName:WBUITreeNodeDidRemoveChildNotification
                                             object:self
                                           userInfo:info];
  }
}

- (void)removeAllChildren {
  if ([self hasChildren]) {
    if (wb_utFlags.undo) {
      [[self undoManager] registerUndoWithTarget:self selector:@selector(setChildren:) object:[self children]];
    }
    if (wb_utFlags.notify) {
      [[self notificationCenter] postNotificationName:WBUITreeNodeWillSetChildrenNotification
                                               object:self
                                             userInfo:nil];
    }
    [super removeAllChildren];
    if (wb_utFlags.notify) {
      [[self notificationCenter] postNotificationName:WBUITreeNodeDidSetChildrenNotification
                                               object:self
                                             userInfo:nil];
    }
  }
}

#pragma mark -
- (void)insertSibling:(WBTreeNode *)sibling {
  if (wb_utFlags.undo) {
    [[[self undoManager] prepareWithInvocationTarget:sibling] remove];
  }
  NSDictionary *info = nil;
  WBBaseUITreeNode *parent = [self parent];
  if (parent && wb_utFlags.notify) {
    info = [NSDictionary dictionaryWithObject:sibling forKey:WBInsertedChild];
    [[parent notificationCenter] postNotificationName:WBUITreeNodeWillInsertChildNotification
                                               object:parent
                                             userInfo:info];
  }
  [super insertSibling:sibling];
  if (parent && wb_utFlags.notify) {
    [[parent notificationCenter] postNotificationName:WBUITreeNodeDidInsertChildNotification
                                               object:parent
                                             userInfo:info];
  }
}

- (void)remove {
  WBBaseUITreeNode *parent = [self parent];
  if (parent && wb_utFlags.undo) {
    [(WBTreeNode *)[[self undoManager] prepareWithInvocationTarget:parent] insertChild:self atIndex:[parent indexOfChild:self]];
  }
  NSDictionary *info = nil;
  if (parent && wb_utFlags.notify) {
    info = [NSDictionary dictionaryWithObject:self forKey:WBRemovedChild];
    [[parent notificationCenter] postNotificationName:WBUITreeNodeWillRemoveChildNotification
                                               object:parent
                                             userInfo:info];
  }
  [super remove];
  if (parent && wb_utFlags.notify) {
    [[parent notificationCenter] postNotificationName:WBUITreeNodeDidRemoveChildNotification
                                               object:parent
                                             userInfo:info];
  }
}

#pragma mark -
- (void)setSortedChildren:(NSArray *)ordered {
  if (wb_utFlags.undo) {
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setSortedChildren:) object:[self children]];
  }
  if (wb_utFlags.notify) {
    [[self notificationCenter] postNotificationName:WBUITreeNodeWillSortChildrenNotification object:self];
  }
  [super setSortedChildren:ordered];
  if (wb_utFlags.notify) {
    [[self notificationCenter] postNotificationName:WBUITreeNodeDidSortChildrenNotification object:self];
  }
}

#pragma mark -
#pragma mark Children KVC compliance
- (void)setChildren:(NSArray *)objects {
  if (wb_utFlags.undo) {
    [[[self undoManager] prepareWithInvocationTarget:self] removeAllChildren];
  }
  NSDictionary *info = nil;
  if (wb_utFlags.notify) {
    if ([objects count] > 0)
      info = [NSDictionary dictionaryWithObject:objects forKey:WBNewChildren];
    [[self notificationCenter] postNotificationName:WBUITreeNodeWillSetChildrenNotification
                                             object:self
                                           userInfo:info];
  }
  [super setChildren:objects];
  if (wb_utFlags.notify) {
    [[self notificationCenter] postNotificationName:WBUITreeNodeDidSetChildrenNotification
                                             object:self
                                           userInfo:info];
  }
}

@end
