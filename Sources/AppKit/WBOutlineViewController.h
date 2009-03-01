/*
 *  WBOutlineViewController.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@class WBUITreeNode;
WB_CLASS_EXPORT
@interface WBOutlineViewController : NSObject {
@private
  WBUITreeNode *wb_root;
  NSOutlineView *wb_outline;
  struct _wb_ocFlags {
    unsigned int autoselect:1;
    unsigned int displayRoot:1;
    unsigned int:6;
  } wb_ocFlags;
  id wb_delegate;
}

- (id)initWithOutlineView:(NSOutlineView *)aView;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)autoSelect;
- (void)setAutoSelect:(BOOL)flag;

- (BOOL)displayRoot;
- (void)setDisplayRoot:(BOOL)flag;

- (id)root;
- (void)setRoot:(WBUITreeNode *)root;

- (NSOutlineView *)outlineView;
- (void)setOutlineView:(NSOutlineView *)anOutline;

- (BOOL)containsNode:(id)aNode;

- (void)displayNode:(WBUITreeNode *)aNode;
- (void)editNode:(WBUITreeNode *)aNode column:(NSInteger)column;

- (id)selectedNode;
- (void)setSelectedNode:(WBUITreeNode *)anObject;
- (void)setSelectedNode:(WBUITreeNode *)anObject display:(BOOL)display;

/* Drag'n drop helper */
- (BOOL)dropObject:(id)anObject item:(id)item childIndex:(NSInteger)index operation:(NSDragOperation)op;

@end
