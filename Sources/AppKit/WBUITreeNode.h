/*
 *  WBUITreeNode.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBExtendedTreeNode.h>

#import <Cocoa/Cocoa.h>

/* Notification keys */
WB_EXPORT
NSString * const WBNewChildren;
WB_EXPORT
NSString * const WBRemovedChild;
WB_EXPORT
NSString * const WBReplacedChild;
WB_EXPORT
NSString * const WBInsertedChild;

/* Notification */
WB_EXPORT
NSString * const WBUITreeNodeWillChangeNameNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidChangeNameNotification;

WB_EXPORT
NSString * const WBUITreeNodeWillInsertChildNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidInsertChildNotification;

WB_EXPORT
NSString * const WBUITreeNodeWillRemoveChildNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidRemoveChildNotification;

WB_EXPORT
NSString * const WBUITreeNodeWillReplaceChildNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidReplaceChildNotification;

WB_EXPORT
NSString * const WBUITreeNodeWillSetChildrenNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidSetChildrenNotification;

WB_EXPORT
NSString * const WBUITreeNodeWillSortChildrenNotification;
WB_EXPORT
NSString * const WBUITreeNodeDidSortChildrenNotification;

/* Private class */
@interface WBBaseUITreeNode : WBExtendedTreeNode <NSCopying, NSCoding> {
@private
  struct _wb_utFlags {
    unsigned int leaf:1;
    unsigned int undo:1;
    unsigned int group:1;
    unsigned int notify:1;
    unsigned int editable:1;
    unsigned int removable:1;
    unsigned int draggable:1;
    unsigned int uncollapsable:1;
    /* reserved */
    unsigned int reserved:8;
  } wb_utFlags;
}

+ (instancetype)nodeWithName:(NSString *)aName;
+ (instancetype)nodeWithName:(NSString *)aName icon:(NSImage *)anIcon;

- (instancetype)init;
- (instancetype)initWithName:(NSString *)aName;
- (instancetype)initWithName:(NSString *)aName icon:(NSImage *)anIcon; // designated initializer

- (void)sortByName;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anIcon;

- (NSString *)name;
- (void)setName:(NSString *)aName;

/* Used as kvc key for image and text cells */
- (id)representation;
- (void)setRepresentation:(NSString *)aName;

- (NSUndoManager *)undoManager;
- (NSNotificationCenter *)notificationCenter;

- (BOOL)notify;
- (void)setNotify:(BOOL)notify;

- (BOOL)registerUndo;
- (void)setRegisterUndo:(BOOL)flag;

- (BOOL)isLeaf;
- (void)setIsLeaf:(BOOL)flag;

- (BOOL)isGroupNode;
- (void)setIsGroupNode:(BOOL)flag;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)flag;

- (BOOL)isRemovable;
- (void)setRemovable:(BOOL)flag;

- (BOOL)isDraggable;
- (void)setDraggable:(BOOL)flag;

- (BOOL)isCollapsable;
- (void)setCollapsable:(BOOL)flag;

/* protected methods */
- (void)wb_setIcon:(NSImage *)anIcon;
- (void)wb_setName:(NSString *)aName;

@end

WB_OBJC_EXPORT
@interface WBUITreeNode : WBBaseUITreeNode <NSCopying, NSCoding> {
@private
  NSImage *wb_icon;
  NSString *wb_name;
}


@end
