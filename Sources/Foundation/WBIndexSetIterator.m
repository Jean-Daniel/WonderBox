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
void __WBIndexSetIteratorInitialize(WBIndexSetIterator *iter) {
  iter->_cnt = iter->_idx = 0;
  // Invalid range
  if (NSNotFound == iter->_state.location || NSNotFound == iter->_state.length)
    iter->_indexes = nil;
}

WBIndexSetIterator WBIndexSetIteratorCreate(NSIndexSet *aSet) {
  NSRange range = NSMakeRange(0, [aSet lastIndex]);
  if (NSNotFound != range.length) range.length += 1; // case where last index is 0.
  return WBIndexSetIteratorCreateWithRange(aSet, range);
}

WBIndexSetIterator WBIndexSetIteratorCreateWithRange(NSIndexSet *aSet, NSRange aRange) {
  WBIndexSetIterator iter = {
    ._indexes = aSet,
    ._state = aRange,
  };
  __WBIndexSetIteratorInitialize(&iter);
  return iter;
}

NSUInteger WBIndexSetIteratorNextIndex(WBIndexSetIterator *iter) {
  NSCParameterAssert(iter);
  if (!iter || iter->_idx < 0) return NSNotFound;
  if (iter->_cnt == iter->_idx) {
    // The array is empty, we have to refill.
    if (!iter->_indexes) return NSNotFound; // we are done
    iter->_cnt = [iter->_indexes getIndexes:iter->_values maxCount:16 inIndexRange:&iter->_state];

    if (iter->_cnt < 16) { // if count less than provided space, we reached the end. We no longer need the index set.
      iter->_indexes = nil;
      if (0 == iter->_cnt) // we are done
        return NSNotFound;
    }

    WBAssert(iter->_cnt <= 16, @"Buffer overflow !");
    iter->_idx = 0;
  }
  NSUInteger result = iter->_values[iter->_idx];
  iter->_idx++;
  return result;
}
