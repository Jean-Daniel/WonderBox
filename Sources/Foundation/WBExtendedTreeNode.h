/*
 *  WBExtendedTreeNode.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBExtendedTreeNode
    @abstract   (description)
    @discussion (description)
*/

#import <WonderBox/WBTreeNode.h>

/*!
  @class
  @abstract   A WBTreeNode that is KVC/KVO Compliant for children key.
  @discussion This class override all node manipulation methods to correctly send KVO notifications.
*/
WB_OBJC_EXPORT
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
