/*
 *  WBOutlineViewController.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBOutlineViewController.h)
#import WBHEADER(WBUITreeNode.h)

#define _ContainsNode(item)		 		({(nil != item) && ([item findRoot] == wb_root);})

@implementation WBOutlineViewController

- (id)initWithOutlineView:(NSOutlineView *)aView {
  if (self = [super init]) {
    if (aView)
      [self setOutlineView:aView];
  }
  return self;
}

- (id)init {
  return [self initWithOutlineView:nil];
}

- (void)dealloc {
  [self setRoot:nil];
  [wb_outline release];
  [super dealloc];
}

#pragma mark -
- (id)delegate {
  return wb_delegate;
}
- (void)setDelegate:(id)delegate {
  wb_delegate = delegate;
}

- (BOOL)autoSelect {
  return wb_ocFlags.autoselect;
}

- (void)setAutoSelect:(BOOL)flag {
  WBFlagSet(wb_ocFlags.autoselect, flag);
}

- (BOOL)displayRoot {
  return wb_ocFlags.displayRoot;
}
- (void)setDisplayRoot:(BOOL)flag {
  WBFlagSet(wb_ocFlags.displayRoot, flag);
}

- (id)root {
  return wb_root;
}
- (void)setRoot:(WBBaseUITreeNode *)root {
  NSParameterAssert(root == nil || [root notify]);
  if (wb_root) {
    [[wb_root notificationCenter] removeObserver:self];
  }
  WBSetterRetain(&wb_root, root);
  if (wb_root) {
    NSNotificationCenter *notify = [wb_root notificationCenter];
    [notify addObserver:self selector:@selector(didChangeNodeName:)
                   name:WBUITreeNodeDidChangeNameNotification
                 object:nil];
    /* Collapse when removing last item */
    [notify addObserver:self selector:@selector(willSetChildren:)
                   name:WBUITreeNodeWillRemoveChildNotification
                 object:nil];
    [notify addObserver:self selector:@selector(willSetChildren:)
                   name:WBUITreeNodeWillSetChildrenNotification
                 object:nil];
    /* Reload item and autoselect if needed when insert or remove */
    [notify addObserver:self selector:@selector(didUpdateChildren:)
                   name:WBUITreeNodeDidInsertChildNotification
                 object:nil];
    [notify addObserver:self selector:@selector(didUpdateChildren:)
                   name:WBUITreeNodeDidRemoveChildNotification
                 object:nil];
    [notify addObserver:self selector:@selector(didUpdateChildren:)
                   name:WBUITreeNodeDidReplaceChildNotification
                 object:nil];
    
    [notify addObserver:self selector:@selector(didUpdateChildren:)
                   name:WBUITreeNodeDidSetChildrenNotification
                 object:nil];
    [notify addObserver:self selector:@selector(didUpdateChildren:)
                   name:WBUITreeNodeDidSortChildrenNotification
                 object:nil];
  }
  [wb_outline reloadData];
  // expand root uncollapsable items
  if (root) {
    if ([self displayRoot]) {
      if (![root isCollapsable])
        [wb_outline expandItem:root];
    } else {
      for (WBBaseUITreeNode *node in [root childEnumerator]) {
        if (![node isCollapsable])
          [wb_outline expandItem:node];
      }
    }
  }
}

- (NSOutlineView *)outlineView {
  return wb_outline;
}

- (void)setOutlineView:(NSOutlineView *)anOutline {
  if (wb_outline) {
    [wb_outline setDataSource:nil];
    [wb_outline release];
  }
  wb_outline = [anOutline retain];
  if (wb_outline) {
    [wb_outline setDataSource:self];
  }
}

- (BOOL)containsNode:(id)aNode {
  return _ContainsNode(aNode);
}

- (void)displayNode:(WBBaseUITreeNode *)aNode {
  if (_ContainsNode(aNode)) {
    // Expand all parents
    WBBaseUITreeNode *parent = [aNode parent];
    if (parent) {
      NSMutableArray *path = [NSMutableArray array];
      do {
        [path addObject:parent];
        parent = [parent parent];
      } while (parent);
      NSEnumerator *parents = [path reverseObjectEnumerator];
      while (parent = [parents nextObject]) {
        [wb_outline expandItem:parent];
      }
    }
    //    int row = [wb_outline rowForItem:aNode];
    //    if (row >= 0)
    //      [wb_outline scrollRowToVisible:row];
  }
}

- (void)editNode:(WBBaseUITreeNode *)aNode column:(NSInteger)column {
  [self setSelectedNode:aNode display:YES];
  [wb_outline editColumn:column row:[wb_outline rowForItem:aNode] withEvent:nil select:YES];
}

- (id)selectedNode {
  NSInteger idx = [wb_outline selectedRow];
  return idx != -1 ? [wb_outline itemAtRow:idx] : nil;
}

- (void)setSelectedNode:(WBBaseUITreeNode *)anObject {
  [self setSelectedNode:anObject display:YES];
}

#pragma mark Internal Methods
- (void)setSelectedNode:(WBBaseUITreeNode *)anObject display:(BOOL)display {
  if (_ContainsNode(anObject)) {
    if (display) [self displayNode:anObject];
    // Select Row
    NSInteger row = [wb_outline rowForItem:anObject];
    if (row >= 0) {
      if ([wb_outline selectedRow] == row) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:wb_outline];
      } else {
        [wb_outline selectRow:row byExtendingSelection:NO];
        [wb_outline scrollRowToVisible:row];
      }
    }
  }
}

#pragma mark Notifications
- (void)didChangeNodeName:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (_ContainsNode(item)) 
    [wb_outline reloadItem:item];
}

- (void)willSetChildren:(NSNotification *)aNotification {
  id item = [aNotification object];
  
  if (_ContainsNode(item)) {
    /* If remove all children (~ "Set Children" with nil user info) ... */
    BOOL collapse = ![aNotification userInfo];
    if (!collapse) {
      /* ... or remove last child ... */
      collapse = [[aNotification userInfo] objectForKey:WBRemovedChild] != nil && [item count] == 1;
    }
    /* ... collapse item */
    if (collapse)
      [wb_outline collapseItem:item];
  }
}

- (void)didUpdateChildren:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (_ContainsNode(item)) {
    if (wb_root == item && ![self displayRoot])
      [wb_outline reloadItem:nil reloadChildren:YES];
    else
      [wb_outline reloadItem:item reloadChildren:[wb_outline isItemExpanded:item]];
    
    WBBaseUITreeNode *child = [[aNotification userInfo] objectForKey:WBInsertedChild];
    if (child) {
      if (![child isCollapsable])
        [wb_outline expandItem:child];
      /* if autoselect and did insert child */
      if (wb_ocFlags.autoselect) {
        [self setSelectedNode:child];
      } else {
        [self displayNode:child];
      }
    }
  }
}

#pragma mark -
#pragma mark OutlineView DataSource
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return (nil == item) ? YES : ([item respondsToSelector:@selector(isLeaf)]) ? ![item isLeaf] : [item hasChildren];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (nil == item) {
    if (wb_ocFlags.displayRoot) {
      return wb_root ? 1 : 0;
    } else {
      return [wb_root count];
    }
  } else {
    return [item count];
  }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)anIndex ofItem:(id)item {
  return (nil == item) ? (wb_ocFlags.displayRoot ? (id)wb_root : [wb_root childAtIndex:anIndex]) : [item childAtIndex:anIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  NSString *identifier = [tableColumn identifier];
  if (!identifier) {
    return nil;
  } else if ([identifier isEqualToString:@"__item__"]) {
    return item;
  } else {
    return [item valueForKey:[tableColumn identifier]];
  }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if ([item respondsToSelector:@selector(isEditable)] && [item isEditable]) {
    @try {
      NSString *name = [item name];
      if ([object isKindOfClass:[NSString class]] && ![name isEqualToString:object]) {
        [(WBBaseUITreeNode *)item setName:object];
      }
    } @catch (id exception) {
      WBLogException(exception);
    }
  }
}

#pragma mark -
#pragma mark Drag & Drop
- (BOOL)dropObject:(id)anObject item:(id)item childIndex:(NSInteger)anIndex operation:(NSDragOperation)op {
  NSParameterAssert(item);
  NSParameterAssert(anObject);
  
  /* Only accept copy if not owner */
  if (!_ContainsNode(anObject)) {
    if (op & NSDragOperationCopy) {
      op = NSDragOperationCopy;
    } else {
      return NO;
    }
  }
  
  /* If move, check parent, and avoid nop */
  if (op != NSDragOperationCopy) {
    /* Check parents */
    id parent = item;
    do {
      if (anObject == parent) {
        return NO;
      }
    } while (parent = [parent parent]);
    
    /* If move and same parent ... */
    if ([anObject parent] == item) {
      /* ... and anIndex -1 (drop on parent) ... */
      if (anIndex < 0) {
        return YES;
      }
      NSUInteger idx = [item indexOfChild:anObject];
      /* ... or destination is line above or belove dragged item */
      if (idx != NSNotFound && (anIndex == (NSInteger)idx) || (anIndex == (NSInteger)idx + 1)) {
        return YES;
      }
    }
  }
  
  
  id insert = nil;
  NSInteger srcIdx = [anObject index];
  /* If move allowed */
  if (op == NSDragOperationCopy) {
    /* Copy */
    insert = [anObject copy];
  } else {
    /* Have to check parent before removing object */
    if (([anObject parent] == item) && (srcIdx <= anIndex)) anIndex--;
    insert = [anObject retain];
    [anObject remove];
  }
  if (insert) {
    /* Insert the item in tree */
    if (anIndex < 0) {
      [item appendChild:insert];
    } else {
      [item insertChild:insert atIndex:anIndex];
    }
    [insert release];
    return YES;
  }
  DLog(@"ERROR: Undefine error while dropping item. Cannot copy item");
  return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
  if ([wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView writeItems:items toPasteboard:pboard];
  }
  return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info
                  proposedItem:(id)item proposedChildIndex:(NSInteger)anIndex {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView validateDrop:info proposedItem:item proposedChildIndex:anIndex];
  }
  return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)anIndex {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView acceptDrop:info item:item childIndex:anIndex];
  }
  return NO;
}

- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView namesOfPromisedFilesDroppedAtDestination:dropDestination forDraggedItems:items];
  }
  return nil;
}

#pragma mark Other DataSource Methods
- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView sortDescriptorsDidChange:oldDescriptors];
  }
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView itemForPersistentObject:object];
  }
  return nil;
}
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
  if (wb_delegate && [wb_delegate respondsToSelector:_cmd]) {
    return [wb_delegate outlineView:outlineView persistentObjectForItem:item];
  }
  return nil;
}

@end
