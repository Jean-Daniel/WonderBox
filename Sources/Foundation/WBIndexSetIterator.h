/*
 *  WBIndexSetIterator.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

/* FIXME: ARC not supported.
 10.6: Support block. Use NSIndexSet API to iterate indexes.
       TODO: Write a range iterator function that take block as parameter.
 10.7: Use NSIndexSet API to iterate range.
 */

// MARK: Indexes Iterator
typedef struct _WBIndexIterator {
// @private
  int8_t _cnt;
  int8_t _idx;
  NSRange _state;
#if __has_feature(objc_arc)
  void *_indexes; // probably unsafe
#else
  NSIndexSet *_indexes;
#endif
  NSUInteger _values[16];
} WBIndexIterator;

WB_EXPORT
void WBIndexIteratorInitialize(NSIndexSet *aSet, WBIndexIterator *iter);

WB_EXPORT
void WBIndexIteratorInitializeWithRange(NSIndexSet *aSet, NSRange aRange, WBIndexIterator *iter);

/* Internal Method. Never use it directly */
WB_EXPORT bool _WBIndexIteratorGetNext(WBIndexIterator *iter);

WB_INLINE
NSUInteger WBIndexIteratorNext(WBIndexIterator *iter) {
  NSCParameterAssert(iter && iter->_idx >= 0);

  NSUInteger result = NSNotFound;
  if (iter && (iter->_cnt != iter->_idx || _WBIndexIteratorGetNext(iter))) {
    result = iter->_values[iter->_idx];
    iter->_idx++;
  }
  return result;
}

// .Hack: for syntax is not flexible enought to declare 2 variable inside the first statement,
// So, we have to declare either the iterator, or the index out of the for scope.
// We can't hide it adding a level of bracket, else the user would have to close it,
// or we would have to declare a WBIndexesEndIterator() macros.
// To avoid name collision, we create an unique var name using __COUNTER__ macro.
#define __WBIndexesIterator(var, indexes, line) \
  __attribute__((objc_precise_lifetime, unused)) id __indexes##line = indexes; \
  WBIndexIterator __idxIter##line; WBIndexIteratorInitialize(indexes, &__idxIter##line); \
  for (NSUInteger var; (var = WBIndexIteratorNext(&__idxIter##line)) != NSNotFound;)
#define _WBIndexesIterator(var, indexes, cnt) __WBIndexesIterator(var, indexes, cnt)
/*!
 @abstract
   NSIndexSet *indexes;
   WBIndexesIterator(idx, indexes) {
     // do something with idx
   }
 */
#define WBIndexesIterator(var, indexes) _WBIndexesIterator(var, indexes, __COUNTER__)

// We can't use fast iteration for reverse iterator.
#define WBIndexesReverseIterator(var, indexes) for (NSUInteger var = [indexes lastIndex]; indexes != nil && var != NSNotFound; var = [indexes indexLessThanIndex:var])

// MARK: Ranges Iterator
/*!
 @abstract
   NSRange range;
   WBRangeIterator iter = WBRangeIteratorCreate(indexes);
   while (WBRangeIteratorGetNext(&iter, &range)) {
     // Do something with range.
   }
 */
typedef struct _WBRangeIterator {
  // @private
  WBIndexIterator _iter;
  NSUInteger _next;
} WBRangeIterator;

WB_EXPORT
void WBRangeIteratorInitialize(NSIndexSet *aSet, WBRangeIterator *iter);
WB_EXPORT
void WBRangeIteratorInitializeWithRange(NSIndexSet *aSet, NSRange aRange, WBRangeIterator *iter);

WB_EXPORT
bool WBRangeIteratorGetNext(WBRangeIterator *iter, NSRange *range);
