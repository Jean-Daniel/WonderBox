/*
 *  WBExtendedTreeNode.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */
/*!
    @header WBExtendedTreeNode
    @abstract   (description)
    @discussion (description)
*/

#import WBHEADER(WBTreeNode.h)

/*!
	@class
	@abstract	A WBTreeNode that is KVC/KVO Compliant for children key.
	@discussion This class override all node manipulation methods to correctly send KVO notifications.
*/
WB_CLASS_EXPORT
@interface WBExtendedTreeNode : WBTreeNode <NSCopying, NSCoding> {
  @private
}

#pragma mark -
#pragma mark Children KVC compliance
- (NSArray *)children;
- (void)setChildren:(NSArray *)objects;

- (NSUInteger)countOfChildren;
- (id)objectInChildrenAtIndex:(NSUInteger)index;

- (void)insertObject:(id)object inChildrenAtIndex:(NSUInteger)index;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index;

- (void)replaceObjectInChildrenAtIndex:(NSUInteger)index withObject:(id)object;

@end
