/*
 *  WBSerialQueue.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBSerialQueue.h"

#include <dispatch/dispatch.h>

@interface _WBGCDSerialQueue : WBSerialQueue {
@private
  dispatch_queue_t wb_queue;
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait;

@end

@implementation WBSerialQueue

+ (id)allocWithZone:(NSZone *)zone {
  if ([WBSerialQueue class] == self) {
    return [_WBGCDSerialQueue allocWithZone:zone];
  }
  return [super allocWithZone:zone];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg {
  [self addOperationWithTarget:target selector:sel object:arg waitUntilFinished:NO];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait {
  SPXAbstractMethodException();
}

@end

#pragma mark GCD
@interface _WBSerialQueueBlock : NSObject {
@private
  id wb_target;
  SEL wb_action;
  id wb_argument;
}

@property(nonatomic) SEL action;
@property(nonatomic, retain) id target;
@property(nonatomic, retain) id argument;

@end

@implementation _WBGCDSerialQueue

- (id)init {
  if (self = [super init]) {
    wb_queue = dispatch_queue_create("org.shadowlab.serial-queue", NULL);
  }
  return self;
}

- (void)dealloc {
  if (wb_queue)
    dispatch_release(wb_queue);
  [super dealloc];
}

static
void wb_dispatch_execute(void *ctxt) {
  _WBSerialQueueBlock *block = (__bridge_transfer _WBSerialQueueBlock *)ctxt;
  @try {
    [block.target performSelector:block.action withObject:block.argument];
  } @catch (id exception) {
    SPXLogException(exception);
  }
  spx_release(block);
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait {
  _WBSerialQueueBlock *block = [[_WBSerialQueueBlock alloc] init]; // leak: released in wb_dispatch_execute
  block.target = target;
  block.argument = arg;
  block.action = sel;
  if (shouldWait) {
    dispatch_sync_f(wb_queue, (__bridge_retained void *)block, wb_dispatch_execute);
  } else {
    dispatch_async_f(wb_queue, (__bridge_retained void *)block, wb_dispatch_execute);
  }
}

@end

@implementation _WBSerialQueueBlock

@synthesize target = wb_target;
@synthesize action = wb_action;
@synthesize argument = wb_argument;

- (void)dealloc {
  spx_release(wb_argument);
  spx_release(wb_target);
  [super dealloc];
}


@end
