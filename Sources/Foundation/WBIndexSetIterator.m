/*
 *  WBIndexSetIterator.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBIndexSetIterator.h)

WB_INLINE
void __WBIndexIteratorInitialize(WBIndexIterator *iter) {
  iter->_cnt = iter->_idx = 0;
  // Invalid range
  if (NSNotFound == iter->_state.location || NSNotFound == iter->_state.length)
    iter->_indexes = nil;
}

WBIndexIterator WBIndexIteratorCreate(NSIndexSet *aSet) {
  NSRange range = NSMakeRange(0, [aSet lastIndex]);
  if (NSNotFound != range.length) range.length += 1; // case where last index is 0.
  return WBIndexIteratorCreateWithRange(aSet, range);
}

WBIndexIterator WBIndexIteratorCreateWithRange(NSIndexSet *aSet, NSRange aRange) {
  WBIndexIterator iter = {
    ._indexes = aSet,
    ._state = aRange,
  };
  __WBIndexIteratorInitialize(&iter);
  return iter;
}

bool _WBIndexIteratorGetNext(WBIndexIterator *iter) {
  // The array is empty, we have to refill.
  if (!iter->_indexes) return false; // we are done
  iter->_cnt = [iter->_indexes getIndexes:iter->_values maxCount:16 inIndexRange:&iter->_state];

  if (iter->_cnt < 16) { // if count less than provided space, we reached the end. We no longer need the index set.
    iter->_indexes = nil;
    if (0 == iter->_cnt) // we are done
      return false;
  }

  WBAssert(iter->_cnt <= 16, @"Buffer overflow !");
  iter->_idx = 0;
  return true;
}

// MARK: Range
WBRangeIterator WBRangeIteratorCreate(NSIndexSet *aSet) {
  WBRangeIterator iter = {
    ._iter = WBIndexIteratorCreate(aSet)
  };
  iter._next = WBIndexIteratorNext(&iter._iter);
  return iter;
}
WBRangeIterator WBRangeIteratorCreateWithRange(NSIndexSet *aSet, NSRange aRange) {
  WBRangeIterator iter = {
    ._iter = WBIndexIteratorCreateWithRange(aSet, aRange)
  };
  iter._next = WBIndexIteratorNext(&iter._iter);
  return iter;
}

bool WBRangeIteratorGetNext(WBRangeIterator *iter, NSRange *range) {
  if (!iter || !range) return false;
  if (NSNotFound == iter->_next) return false;

  range->location = iter->_next;
  range->length = 1;
  NSUInteger next = WBIndexIteratorNext(&iter->_iter);
  while (next == iter->_next + 1) {
    range->length++;
    iter->_next = next;
    next = WBIndexIteratorNext(&iter->_iter);
  }
  // Save last value
  iter->_next = next;
  return true;
}
