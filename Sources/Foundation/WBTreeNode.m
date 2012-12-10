/*
 *  WBTreeNode.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTreeNode.h>

@interface _WBTreeChildEnumerator : NSEnumerator {
  @protected
  WBTreeNode *wb_root;
  WBTreeNode *wb_node;
}

- (id)initWithRootNode:(WBTreeNode *)node;

@end

@interface _WBTreeDeepEnumerator : _WBTreeChildEnumerator {
}
@end

#pragma mark -
@implementation WBTreeNode
#pragma mark Protocol Implementation
- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super init]) {
    wb_parent = [aCoder decodeObjectForKey:@"Parent"];
    wb_sibling = [[aCoder decodeObjectForKey:@"Sibling"] retain];
    id children = [aCoder decodeObjectForKey:@"Children"];
    /* Just have to restore first child. Other objects are sibling of first child */
    if ([children count])
      wb_child =  [[children objectAtIndex:0] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeConditionalObject:wb_parent forKey:@"Parent"];
  /* Encode conditionaly so root sibling are not encoded */
  [aCoder encodeConditionalObject:wb_sibling forKey:@"Sibling"];
  /* Encode all children */
  [aCoder encodeObject:[self children] forKey:@"Children"];
}

- (id)copyWithZone:(NSZone *)aZone {
  WBTreeNode *copy = NSAllocateObject([self class], 0, aZone);
  if (wb_child) {
    copy->wb_child = [wb_child copyWithZone:aZone];
    copy->wb_child->wb_parent = copy;

    WBTreeNode *child = copy->wb_child;
    WBTreeNode *sibling = wb_child->wb_sibling;
    while (sibling) {
      child->wb_sibling = [sibling copyWithZone:aZone];
      child->wb_sibling->wb_parent = child->wb_parent;

      child = child->wb_sibling;
      sibling = sibling->wb_sibling;
    }
  }
  return copy;
}

#pragma mark -
+ (id)node {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  if (self = [super init]) {

  }
  return self;
}

- (void)dealloc {
  [wb_child release];
  [wb_sibling release];
  spx_dealloc();
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p>{parent = %p, children = %lu, sibling = %p}",
    NSStringFromClass([self class]), self,
    wb_parent, (unsigned long)[self count], wb_sibling];
}

#pragma mark -
- (id)parent {
  return wb_parent;
}
- (void)setParent:(WBTreeNode *)parent {
  wb_parent = parent;
}

- (BOOL)isChildOf:(WBTreeNode *)parent {
  if (!parent) return NO;
  WBTreeNode *ancestor = self;
  do {
    if (ancestor == parent)
      return YES;
  } while ((ancestor = ancestor->wb_parent));
  return NO;
}

- (id)nextSibling {
  return wb_sibling;
}

- (NSUInteger)siblingCount {
  if (wb_parent) {
    return [wb_parent count];
  } else {
    WBTreeNode *node = self;
    NSUInteger count = 0;
    do {
      count++;
    } while ((node = node->wb_sibling));
    return count;
  }
}

- (NSUInteger)index {
  return (wb_parent) ? [wb_parent indexOfChild:self] : NSNotFound;
}

- (id)findRoot {
  WBTreeNode *tree = self;
  while (tree->wb_parent)
    tree = tree->wb_parent;
  return tree;
}

#pragma mark Child access
- (NSUInteger)count {
  NSUInteger cnt = 0;
  WBTreeNode *node = wb_child;
  while (node) {
    cnt++;
    node = node->wb_sibling;
  }
  return cnt;
}
- (BOOL)hasChildren {
  return wb_child != nil;
}

- (id)firstChild {
  return wb_child;
}

- (id)lastChild {
  WBTreeNode *last = nil;
  if (wb_child) {
    last = wb_child;
    while (last->wb_sibling)
      last = last->wb_sibling;
  }
  return last;
}

/* Must return a mutable array for sort functions */
- (NSArray *)children {
  NSMutableArray *children = [NSMutableArray array];
  WBTreeNode *node = wb_child;
  while (node) {
    [children addObject:node];
    node = node->wb_sibling;
  }
  return children;
}

- (id)childAtIndex:(NSUInteger)anIndex {
  WBTreeNode *node = wb_child;
  NSUInteger idx = anIndex;
  while (node) {
    if (0 == idx) return node;
    idx--;
    node = node->wb_sibling;
  }
  SPXThrowException(NSRangeException, @"index (%lu) beyond bounds (%lu)",
                    (unsigned long)anIndex, (unsigned long)[self count]);
}

- (NSUInteger)indexOfChild:(WBTreeNode *)aChild {
  if ([aChild parent] == self) {
    NSUInteger idx = 0;
    WBTreeNode *child = wb_child;
    BOOL (*isEqual)(id, SEL, id) = (BOOL(*)(id, SEL, id))[aChild methodForSelector:@selector(isEqual:)];
    do {
      if (isEqual(aChild, @selector(isEqual:), child)) {
        return idx;
      }
      idx++;
    } while ((child = child->wb_sibling));
  }
  return NSNotFound;
}

- (BOOL)containsChild:(WBTreeNode *)aChild {
  return [self indexOfChild:aChild] != NSNotFound;
}

- (NSEnumerator *)childEnumerator {
  return [[[_WBTreeChildEnumerator alloc] initWithRootNode:self] autorelease];
}
- (NSEnumerator *)deepChildEnumerator {
  return [[[_WBTreeDeepEnumerator alloc] initWithRootNode:self] autorelease];
}

#pragma mark -
- (void)makeChildrenPerformSelector:(SEL)aSelector {
  NSParameterAssert(nil != aSelector);
  WBTreeNode *node = wb_child;
  while (node) {
    [node performSelector:aSelector];
    node = node->wb_sibling;
  }
}

- (void)makeChildrenPerformSelector:(SEL)aSelector withObject:(id)object {
  NSParameterAssert(nil != aSelector);
  WBTreeNode *node = wb_child;
  while (node) {
    [node performSelector:aSelector withObject:object];
    node = node->wb_sibling;
  }
}

#pragma mark -
- (void)wb_remove {
  if (wb_parent)
    [self setParent:nil];
  wb_sibling = nil;
  [self release];
}

- (void)performOperation:(WBTreeOperation)op atIndex:(NSUInteger)anIndex withChild:(WBTreeNode *)child {
  if (child && child->wb_parent) {
    SPXThrowException(NSInvalidArgumentException, @"Cannot append node with parent.");
  }

  /* If child is a subtree, find last node and set parents */
  WBTreeNode *last = child;
  if (last) {
    [last setParent:self];
    while (last->wb_sibling) {
      last = last->wb_sibling;
      NSAssert(nil == last->wb_parent, @"Should not append node with parent not nil");
      [last setParent:self];
    }
  }
  /* append and has 0 child, or anIndex == 0 and insert or replace */
  if ((0 == anIndex && op != kWBTreeOperationAppend) || (op == kWBTreeOperationAppend && !wb_child)) {
    switch (op) {
      case kWBTreeOperationInsert:
      case kWBTreeOperationAppend:
        last->wb_sibling = wb_child;
        break;
      case kWBTreeOperationRemove:
      case kWBTreeOperationReplace:
        if (!wb_child) {
          SPXThrowException(NSRangeException, @"index (%lu) beyond bounds (%lu)",
                            (unsigned long)anIndex, (unsigned long)[self count]);
        } else {
          if (!child) {
            /* child is retain just below, so we have to release it here */
            child = [wb_child->wb_sibling autorelease];
          } else if (last) {
            /* No need to retain. wb_remove release only self */
            last->wb_sibling = wb_child->wb_sibling;
          }
          [wb_child wb_remove];
        }
        break;
    }
    /* Retain at end to avoid leak when raise an exception */
    wb_child = [child retain];
  } else {
    WBTreeNode *previous = (op == kWBTreeOperationAppend) ? [self lastChild] : [self childAtIndex:anIndex -1];
    WBTreeNode *current = previous ? previous->wb_sibling : nil;
    switch (op) {
      case kWBTreeOperationInsert:
        last->wb_sibling = current;
        break;
      case kWBTreeOperationRemove:
      case kWBTreeOperationReplace:
        if (!current) {
          SPXThrowException(NSRangeException, @"index (%lu) beyond bounds (%lu)",
                            (unsigned long)anIndex, (unsigned long)[self count]);
        } else {
          if (last) {
            last->wb_sibling = current->wb_sibling;
          } else {
            previous->wb_sibling = current->wb_sibling;
            previous = nil;
          }
          [current wb_remove];
        }
        break;
      default:
        break;
    }
    /* Retain at end to avoid leak when raise an exception */
    if (previous)
      previous->wb_sibling = [child retain];
  }
}

#pragma mark Nodes Methods
- (void)prependChild:(WBTreeNode *)child {
  NSParameterAssert(nil != child);
  NSAssert(nil == child->wb_sibling, @"Must remove sibling from newChild first");
  [self performOperation:kWBTreeOperationInsert atIndex:0 withChild:child];
}

- (void)appendChild:(WBTreeNode *)child {
  NSParameterAssert(nil != child);
  [self performOperation:kWBTreeOperationAppend atIndex:0 withChild:child];
}

- (void)insertChild:(WBTreeNode *)newChild atIndex:(NSUInteger)anIndex {
  NSParameterAssert(nil != newChild);
  NSAssert(nil == newChild->wb_sibling, @"Must remove sibling from newChild first");
  [self performOperation:kWBTreeOperationInsert atIndex:anIndex withChild:newChild];
}

- (void)replaceChildAtIndex:(NSUInteger)anIndex withChild:(WBTreeNode *)child {
  NSParameterAssert(nil != child);
  NSParameterAssert(nil == child->wb_sibling);
  [self performOperation:kWBTreeOperationReplace atIndex:anIndex withChild:child];
}

- (void)removeChildAtIndex:(NSUInteger)anIndex {
  [self performOperation:kWBTreeOperationRemove atIndex:anIndex withChild:nil];
}

- (void)removeAllChildren {
  WBTreeNode *nextChild = wb_child;
  while (nextChild) {
    WBTreeNode *sibling = nextChild->wb_sibling;
    [nextChild wb_remove];
    nextChild = sibling;
  }
  wb_child = nil;
}

#pragma mark -
/* Direct Node manipulation (for faster access) */
- (void)insertSibling:(WBTreeNode *)sibling {
  NSParameterAssert(sibling);
  NSParameterAssert(wb_parent);
  NSAssert(nil == sibling->wb_sibling, @"Must remove sibling from newChild first");
  if (sibling->wb_parent) {
    SPXThrowException(NSInvalidArgumentException, @"Cannot append newChild with parent.");
  }
  [sibling retain];
  [sibling setParent:self->wb_parent];
  sibling->wb_sibling = self->wb_sibling;
  self->wb_sibling = sibling;
}

- (void)remove {
  NSParameterAssert(wb_parent);
  if (wb_parent) {
    if (self == wb_parent->wb_child) {
      wb_parent->wb_child = wb_sibling;
    } else {
      WBTreeNode *previous = nil;
      /* Search previous node */
      for (previous = wb_parent->wb_child; previous; previous = previous->wb_sibling) {
        if (previous->wb_sibling == self) {
          previous->wb_sibling = wb_sibling;
          break;
        }
      }
    }
    [self wb_remove];
  }
}

#pragma mark Sorting
- (void)setSortedChildren:(NSArray *)ordered {
  NSEnumerator *children = [ordered objectEnumerator];
  WBTreeNode *child = nil;
  WBTreeNode *sibling;
  while (sibling = [children nextObject]) {
    sibling->wb_sibling = nil;
    if (child) child->wb_sibling = sibling;
    else self->wb_child = sibling;
    child = sibling;
  }
}

- (void)sortUsingSelector:(SEL)comparator {
  /* If has more than one children */
  if (wb_child && wb_child->wb_sibling) {
    id children = [self children];
    [children sortUsingSelector:comparator];
    [self setSortedChildren:children];
  }
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors {
  /* If has more than one children */
  if (wb_child && wb_child->wb_sibling) {
    id children = [self children];
    [children sortUsingDescriptors:sortDescriptors];
    [self setSortedChildren:children];
  }
}

- (void)sortUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context {
  /* If has more than one children */
  if (wb_child && wb_child->wb_sibling) {
    id children = [self children];
    [children sortUsingFunction:compare context:context];
    [self setSortedChildren:children];
  }
}

@end

#pragma mark -
@implementation _WBTreeChildEnumerator

- (id)initWithRootNode:(WBTreeNode *)node {
  if (self = [super init]) {
    wb_root = [node retain];
    wb_node = [wb_root firstChild];
  }
  return self;
}

- (void)dealloc {
  [wb_root release];
  spx_dealloc();
}

- (id)nextObject {
  WBTreeNode *node = wb_node;
  if (!node) {
    [wb_root release];
    wb_root = nil;
  }
  wb_node = [wb_node nextSibling];
  return node;
}

- (NSArray *)allObjects {
  if (!wb_node) { return [NSArray array]; }

  NSMutableArray *children = [NSMutableArray arrayWithObject:wb_node];
  WBTreeNode *node = wb_node;
  while ((node = [node nextSibling])) {
    [children addObject:node];
  }
  wb_node = nil;
  [wb_root release];
  wb_root = nil;
  return children;
}

@end

#pragma mark -
@implementation _WBTreeDeepEnumerator

- (id)nextObject {
  WBTreeNode *node = wb_node;

  /* End was reached */
  if (!node) {
    [wb_root release];
    wb_root = nil;
  }

  /* On descend d'un niveau */
  WBTreeNode *child = [wb_node firstChild];
  if (!child) {
    /* Si on ne peut pas descendre on se deplace lateralement */
    WBTreeNode *sibling = nil;
    /* Tant qu'on est pas remonte en haut de l'arbre, et qu'on a pas trouvé de voisin */
    while (wb_node && wb_node != wb_root && !(sibling = [wb_node nextSibling]))
      wb_node = [wb_node parent];

    wb_node = sibling;
  } else
    wb_node = child;

  return node;
}

- (NSArray *)allObjects {
  if (!wb_node) { return [NSArray array]; }

  WBTreeNode *node = nil;
  NSMutableArray *children = [NSMutableArray array];
  while (node = [self nextObject])
    [children addObject:node];

  return children;
}

@end
