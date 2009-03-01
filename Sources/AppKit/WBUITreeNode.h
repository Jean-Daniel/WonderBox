/*
 *  WBUITreeNode.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBExtendedTreeNode.h)

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
    /* reserved */
    unsigned int reserved:9;
  } wb_utFlags;
}

+ (id)nodeWithName:(NSString *)aName;
+ (id)nodeWithName:(NSString *)aName icon:(NSImage *)anIcon;

- (id)init;
- (id)initWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName icon:(NSImage *)anIcon; // designated initializer

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

- (BOOL)registerUndo;
- (void)setRegisterUndo:(BOOL)flag;

- (BOOL)notify;
- (void)setNotify:(BOOL)notify;

- (BOOL)isLeaf;
- (void)setLeaf:(BOOL)flag;

- (BOOL)isGroupNode;
- (void)setIsGroupNode:(BOOL)flag;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)flag;

- (BOOL)isRemovable;
- (void)setRemovable:(BOOL)flag;

- (BOOL)isDraggable;
- (void)setDraggable:(BOOL)flag;

/* protected methods */
- (void)wb_setIcon:(NSImage *)anIcon;
- (void)wb_setName:(NSString *)aName;

@end

WB_CLASS_EXPORT
@interface WBUITreeNode : WBBaseUITreeNode <NSCopying, NSCoding> {
@private
  NSImage *wb_icon;
  NSString *wb_name;
}


@end
