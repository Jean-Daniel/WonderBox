/*
 *  WBSerialQueue.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */


@interface WBSerialQueue : NSOperationQueue {
@private
  NSOperation *wb_last;
}

- (void)addOperation:(NSOperation *)op;

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg;

@end
