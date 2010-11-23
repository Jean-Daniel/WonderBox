/*
 *  WBIndexSetIterator.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

// MARK: Indexes Iterator
typedef struct _WBIndexIterator {
// @private
  int8_t _cnt;
  int8_t _idx;
  NSRange _state;
  NSIndexSet *_indexes;
  NSUInteger _values[16];
} WBIndexIterator;

WB_EXPORT
WBIndexIterator WBIndexIteratorCreate(NSIndexSet *aSet);

WB_EXPORT
WBIndexIterator WBIndexIteratorCreateWithRange(NSIndexSet *aSet, NSRange aRange);

WB_EXPORT
NSUInteger WBIndexIteratorNext(WBIndexIterator *iter);

// .Hack: for syntax is not flexible enought to declare 2 variable inside the first statement,
// So, we have to declare either the iterator, or the index out of the for scope.
// We can't hide it adding a level of bracket, else the user would have to close it,
// or we would have to declare a WBIndexesEndIterator() macros.
// To avoid name collision, we create an unique var name using the line number.
#define __WBIndexesIterator(var, indexes, line) \
  WBIndexIterator __idxIter##line = WBIndexIteratorCreate(indexes); \
  for (NSUInteger var; (var = WBIndexIteratorNext(&__idxIter##line)) != NSNotFound;)
// Traditional hack to use __LINE__ in a macro.
#define _WBIndexesIterator(var, indexes, line) __WBIndexesIterator(var, indexes, line)

/*!
 @abstract
   NSIndexSet *indexes;
   WBIndexesIterator(idx, indexes) {
     // do something with idx
   }
 */
#define WBIndexesIterator(var, indexes) _WBIndexesIterator(var, indexes, __LINE__)

// We can't use fast iteration for reverse iterator.
#define WBIndexesReverseIterator(var, indexes) for (NSUInteger var = [indexes lastIndex]; indexes != nil && var != NSNotFound; var = [indexes indexLessThanIndex:var])

// MARK: Ranges Iterator
typedef struct _WBRangeIterator {
  // @private
  WBIndexIterator _iter;
  NSUInteger _next;
} WBRangeIterator;

WB_EXPORT
WBRangeIterator WBRangeIteratorCreate(NSIndexSet *aSet);
WB_EXPORT
WBRangeIterator WBRangeIteratorCreateWithRange(NSIndexSet *aSet, NSRange aRange);

WB_EXPORT
bool WBRangeIteratorGetNext(WBRangeIterator *iter, NSRange *range);
