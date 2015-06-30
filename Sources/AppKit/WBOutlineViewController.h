/*
 *  WBOutlineViewController.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

@class WBBaseUITreeNode;
WB_OBJC_EXPORT
@interface WBOutlineViewController : NSObject {
@private
  WBBaseUITreeNode *wb_root;
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
- (void)setRoot:(WBBaseUITreeNode *)root;

- (NSOutlineView *)outlineView;
- (void)setOutlineView:(NSOutlineView *)anOutline;

- (BOOL)containsNode:(id)aNode;

- (void)displayNode:(WBBaseUITreeNode *)aNode;
- (void)editNode:(WBBaseUITreeNode *)aNode column:(NSInteger)column;

- (id)selectedNode;
- (void)setSelectedNode:(WBBaseUITreeNode *)anObject;
- (void)setSelectedNode:(WBBaseUITreeNode *)anObject display:(BOOL)display;

/* Drag'n drop helper */
- (BOOL)dropObject:(id)anObject item:(id)item childIndex:(NSInteger)index operation:(NSDragOperation)op;

@end
