/*
 *  WBExtendedTreeNode.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */
 
#import WBHEADER(WBExtendedTreeNode.h)

@implementation WBExtendedTreeNode
#pragma mark Protocol Implementation
- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
}

- (id)copyWithZone:(NSZone *)aZone {
  WBExtendedTreeNode *copy = [super copyWithZone:aZone];
  return copy;
}

#pragma mark -
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  return ![key isEqualToString:@"children"];
}

#pragma mark -
#pragma mark Children Notifications
/* Methods covered by -perfomOperation 
- (void)prependChild:(WBTreeNode *)child {
}
- (void)appendChild:(WBTreeNode *)child {
}
- (void)insertChild:(WBTreeNode *)newChild atIndex:(NSUInteger)index {
}
- (void)replaceChildAtIndex:(NSUInteger)index withChild:(WBTreeNode *)child {
}
 - (void)removeChildAtIndex:(NSUInteger)idx {
}
*/
- (void)performOperation:(WBTreeOperation)op atIndex:(NSUInteger)anIndex withChild:(WBTreeNode *)child {
  NSIndexSet *idxes = nil;
  NSKeyValueChange change = 0;
  switch (op) {
    case kWBTreeOperationInsert:
      change = NSKeyValueChangeInsertion;
      idxes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(anIndex, [child siblingCount])];
      break;
    case kWBTreeOperationAppend:
      change = NSKeyValueChangeInsertion;
      idxes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange([self count], [child siblingCount])];
      break;
    case kWBTreeOperationRemove:
      change = NSKeyValueChangeRemoval;
      idxes = [[NSIndexSet alloc] initWithIndex:anIndex];
      break;
    case kWBTreeOperationReplace:
      change = NSKeyValueChangeReplacement;
      idxes = [[NSIndexSet alloc] initWithIndex:anIndex];
      break;
  }
  [self willChange:change valuesAtIndexes:idxes forKey:@"children"];
  [super performOperation:op atIndex:anIndex withChild:child];
  [self didChange:change valuesAtIndexes:idxes forKey:@"children"];
  [idxes release];
}

- (void)removeAllChildren {
  id idxes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self count])];
  [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:idxes forKey:@"children"];
  [super removeAllChildren];
  [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:idxes forKey:@"children"];
}

#pragma mark -
- (void)insertSibling:(WBTreeNode *)newSibling {
  id parent = [self parent];
  NSIndexSet *idxes = nil;
  if (parent) {
    idxes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange([parent indexOfChild:self] + 1, [newSibling siblingCount])];
    [parent willChange:NSKeyValueChangeInsertion valuesAtIndexes:idxes forKey:@"children"];
  }
  [super insertSibling:newSibling];
  if (parent) {
    [parent didChange:NSKeyValueChangeInsertion valuesAtIndexes:idxes forKey:@"children"];
    [idxes release];
  }
}

- (void)remove {
  id parent = [self parent];
  NSIndexSet *idxes = nil;
  if (parent) {
    idxes = [[NSIndexSet alloc] initWithIndex:[parent indexOfChild:self]];
    [parent willChange:NSKeyValueChangeRemoval valuesAtIndexes:idxes forKey:@"children"];
  }
  [super remove];
  if (parent) {
    [parent didChange:NSKeyValueChangeRemoval valuesAtIndexes:idxes forKey:@"children"];
    [idxes release];
  }
}

#pragma mark -
- (void)setSortedChildren:(NSArray *)ordered {
  id idxes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self count])];
  [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:idxes forKey:@"children"];
  [super setSortedChildren:ordered];
  [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:idxes forKey:@"children"];
}

#pragma mark -
#pragma mark Children KVC compliance
- (NSArray *)children {
  return [super children];
}

- (void)setChildren:(NSArray *)objects {
  [self willChangeValueForKey:@"children"];
  if ([self hasChildren]) {
    /* Do not call self to avoid multiple notifications */
    [super removeAllChildren];
  }
  
  if ([objects count] > 0) {
    id child;
    id children = [objects reverseObjectEnumerator];
    while (child = [children nextObject]) {
      /* Do not call self to avoid multiple notifications */
      [super prependChild:child];
    }
  }
  [self didChangeValueForKey:@"children"];
}

- (NSUInteger)countOfChildren {
  return [self count];
}

- (id)objectInChildrenAtIndex:(NSUInteger)anIndex {
  return [self childAtIndex:anIndex];
}

- (void)insertObject:(id)object inChildrenAtIndex:(NSUInteger)anIndex {
  [self insertChild:object atIndex:anIndex];
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)anIndex {
  [self removeChildAtIndex:anIndex];
}

- (void)replaceObjectInChildrenAtIndex:(NSUInteger)anIndex withObject:(id)object {
  [self replaceChildAtIndex:anIndex withChild:object];
}

@end
