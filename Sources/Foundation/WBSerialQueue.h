/*
 *  WBSerialQueue.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

// SHould use GCD when possible instead
@interface WBSerialQueue : NSOperationQueue {
@private
  NSOperation *wb_last;
  NSCondition *wb_event;
}

- (void)addOperation:(NSOperation *)op;
- (void)addOperation:(NSOperation *)op waitUntilFinished:(BOOL)shouldWait;

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg;
- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait;

@end
