/*
 *  WBTreeNode.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBTreeNode
*/

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

/*!
    @class
    @abstract Tree structure.
    @discussion Tree node class to implements Tree structure.
*/
WB_OBJC_EXPORT
@interface WBTreeNode : NSObject <NSCopying, NSCoding>
#pragma mark Initializer
+ (id)node;
- (id)init;

#pragma mark -
/*!
  @method
 @abstract   Returns the root tree of a given tree.
 @result     The root of tree where root is defined as a tree without a parent.
 */
- (id)findRoot;

/*!
  @method
 @abstract   Returns the index of the receiver or <em>NSNotFound</em> if parent is nil.
 */
- (NSUInteger)index;
/*!
  @method
 @abstract   Returns the child of a tree at the specified index.
 @result     The child tree at <i>index</i>.
 */
- (id)childAtIndex:(NSUInteger)index;
/*!
 @method
 @abstract   Get index of child in receiver children array.
 @result     The index of <em>child</em>.
 */
- (NSUInteger)indexOfChild:(WBTreeNode *)child;

/*!
 @method
 @abstract   Check if receiver contains child or not.
 @discussion This method search only in the first level.
 @result     Returns YES of contains <code>aChild</code>.
 */
- (BOOL)containsChild:(WBTreeNode *)aChild;

/*!
  @method
 @abstract   (brief description)
 @result     Returns YES if the receiver has at least one child.
*/
- (BOOL)hasChildren;

/*!
  @method
 @abstract   Returns the number of children in a tree.
 @result     The number of children.
 */
- (NSUInteger)count;

/*!
  @method
 @abstract   Fills the buffer with children from the tree.
 @result     An array of children.
 */
- (NSArray *)children;

/*!
  @method
 @abstract   (brief description)
 @result     A Children enumerator.
*/
- (NSEnumerator *)childEnumerator;

/*!
  @method
 @abstract   Returns an enumerator that enumerate full tree content.
 @result     Returns an NSEnumerator.
*/
- (NSEnumerator *)deepChildEnumerator;

/*!
  @method
 @abstract   Returns the first child of a tree.
 @result     The first child of the receiver or nil if the receiver is empty.
 */
- (id)firstChild;

/*!
  @method
 @abstract   Returns the last child of a tree.
 @result     The last child of the receiver or nil if the receiver is empty.
 */
- (id)lastChild;

/*!
  @method
 @abstract   Returns the next sibling, adjacent to a given tree, in the parent children list.
 @result     The next sibling, adjacent to the receiver.
*/
- (id)nextSibling;


/*!
  @method
 @abstract   Returns the count of sibling. Use with care (see discussion).
 @discussion If this node has a parent, it returns parent child count, else it returns receiver sibling count including self.
 @result     The receiver sibling count (including the receiver).
 */
- (NSUInteger)siblingCount;

/*!
  @method
 @abstract   Returns the parent of a given tree.
 @result     The parent of the tree.
 */
- (id)parent;

/*!
  @method
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      parent (description)
 @result     YES if receiver is equal to parent, or if parent is ancestor of receiver.
 */
- (BOOL)isChildOf:(WBTreeNode *)parent;

#pragma mark -
#pragma mark Add child
/*!
 @method
 @abstract   Inserts a new sibling after a given tree.
 @param      newNode The sibling to add. If this parameter is not a valid WBTreeNode,
 the behavior is undefined. If this parameter is a tree which is already a child
 of another tree (it has a parent), the behavior is undefined.
 */
- (void)insertSibling:(WBTreeNode *)newNode;

/*!
 @method
 @abstract Adds a new child to a tree as the last in its list of children.
 @param child The child tree node to be added. If this parameter is not a valid WBTreeNode, the behavior is undefined.
 If this parameter is a tree which is already a child of any tree, the behavior is undefined.
 Child's sibling are also append.
*/
- (void)appendChild:(WBTreeNode *)child;

/*!
 @method
 @abstract Adds a new child to the specified tree as the first in its list of children.
 @param child The child tree to add to tree. If this parameter is not a valid WBTreeNode,
 the behavior is undefined. If this parameter is a tree which is already a child of
 another tree (it has a parent), the behavior is undefined.
*/
- (void)prependChild:(WBTreeNode *)child;

/*!
 @method
 @abstract   (brief description)
 @param      newChild (description)
 @param      index (description)
*/
- (void)insertChild:(WBTreeNode *)newChild atIndex:(NSUInteger)index;

/*!
 @method
 @abstract   (brief description)
 @param      index (description)
 @param      newChild (description)
*/
- (void)replaceChildAtIndex:(NSUInteger)index withChild:(WBTreeNode *)newChild;

#pragma mark -
#pragma mark Remove
/*!
  @method
 @abstract   Removes a tree from its parent.
*/
- (void)remove;

/*!
  @method
 @abstract   (brief description)
 @param      index (description)
*/
- (void)removeChildAtIndex:(NSUInteger)index;
/*!
  @method
 @abstract   Removes all the children of a tree.
*/
- (void)removeAllChildren;

#pragma mark -
#pragma mark Perform Selector
/*!
  @method
 @abstract   (brief description)
 @param      aSelector (description)
*/
- (void)makeChildrenPerformSelector:(SEL)aSelector;

  /*!
  @method
   @abstract   (brief description)
   @param      aSelector (description)
   @param      object (description)
*/
- (void)makeChildrenPerformSelector:(SEL)aSelector withObject:(id)object;

#pragma mark -
#pragma mark Sort
/*!
  @method
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      comparator (description)
*/
- (void)sortUsingSelector:(SEL)comparator;
/*!
  @method
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      sortDescriptors (description)
 */
- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;
/*!
  @method
 @abstract   (brief description)
 @discussion (comprehensive description)
 @param      compare (description)
 @param      context (description)
 */
- (void)sortUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;

#pragma mark Protected
- (void)setParent:(WBTreeNode *)parent;

@end

#pragma mark -

typedef enum {
  kWBTreeOperationInsert = 0,
  kWBTreeOperationAppend = 1,
  kWBTreeOperationRemove = 2,
  kWBTreeOperationReplace = 3,
} WBTreeOperation;

@interface WBTreeNode (WBTreeProtected)

/* Private Method use by all sorting functions. Never call directly */
- (void)setSortedChildren:(NSArray *)ordered;

- (void)performOperation:(WBTreeOperation)op atIndex:(NSUInteger)index withChild:(WBTreeNode *)child;

@end
