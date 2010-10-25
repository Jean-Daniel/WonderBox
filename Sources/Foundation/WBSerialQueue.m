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

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
#include <dispatch/dispatch.h>
#else
#warning GCD not available with 10.5 SDK
#endif

// FIXME: does not support too many operations.
@interface _WBSerialOperationQueue : WBSerialQueue {
@private
  NSOperation *wb_last;
  NSCondition *wb_event;
  NSOperationQueue *wb_queue;
}

- (void)addOperation:(NSOperation *)op;
- (void)addOperation:(NSOperation *)op waitUntilFinished:(BOOL)shouldWait;

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@interface _WBGCDSerialQueue : WBSerialQueue {
@private
  dispatch_queue_t wb_queue;
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait;

@end
#endif

@implementation WBSerialQueue

+ (id)allocWithZone:(NSZone *)zone {
  if ([WBSerialQueue class] == self) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
    if (dispatch_sync_f)
      return [_WBGCDSerialQueue allocWithZone:zone];
#endif
    return [_WBSerialOperationQueue allocWithZone:zone];
  }
  return [super allocWithZone:zone];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg {
  [self addOperationWithTarget:target selector:sel object:arg waitUntilFinished:NO];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait {
  WBClusterException();
}

@end

@implementation _WBSerialOperationQueue

- (id)init {
  if (self = [super init]) {
    if (![NSOperation instancesRespondToSelector:@selector(waitUntilFinished)])
      wb_event = [[NSCondition alloc] init];

    wb_queue = [[NSOperationQueue alloc] init];
    [wb_queue setMaxConcurrentOperationCount:1];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
    if ([wb_queue respondsToSelector:@selector(setName:)])
      [wb_queue setName:@"org.shadowlab.serial-queue"];
#endif
  }
  return self;
}

- (void)dealloc {
  [wb_queue release];
  [wb_event release];
  [wb_last release];
  [super dealloc];
}

- (void)addOperation:(NSOperation *)op {
  @synchronized(self) {
    if (wb_last)
      [op addDependency:wb_last];

    WBSetterRetain(wb_last, op);
    [op addObserver:self forKeyPath:@"isFinished" options:0 context:[_WBSerialOperationQueue class]];
  }
  [wb_queue addOperation:op];
}

- (void)addOperation:(NSOperation *)op waitUntilFinished:(BOOL)shouldWait {
  NSParameterAssert(op);
  [self addOperation:op];
  if (shouldWait) {
    if (wb_event) {
      [wb_event lock];
      while (![op isFinished])
        [wb_event wait];
      [wb_event unlock];
    } else {
      [op waitUntilFinished];
    }
  }
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait {
  NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:target selector:sel object:arg];
  [self addOperation:op waitUntilFinished:shouldWait];
  [op release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == [_WBSerialOperationQueue class]) {
    @synchronized(self) {
      [object removeObserver:self forKeyPath:@"isFinished"];
      if (wb_last == object)
        WBSetterRetain(wb_last, nil);
    }
    // an op is finished, tell it to all 'synchronous op' waiter.
    [wb_event lock];
    // MUST lock to prevent race condition
    [wb_event broadcast];
    [wb_event unlock];
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

@end

#pragma mark GCD
@interface _WBSerialQueueBlock : NSObject {
@private
  id wb_target;
  SEL wb_action;
  id wb_argument;
}

@property SEL action;
@property(nonatomic, retain) id target;
@property(nonatomic, retain) id argument;

@end
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
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
  _WBSerialQueueBlock *block = (_WBSerialQueueBlock *)ctxt;
  @try {
    [block.target performSelector:block.action withObject:block.argument];
  } @catch (id exception) {
    WBLogException(exception);
  }
  [block release];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait {
  _WBSerialQueueBlock *block = [[_WBSerialQueueBlock alloc] init]; // leak: released in wb_dispatch_execute
  block.target = target;
  block.argument = arg;
  block.action = sel;
  if (shouldWait) {
    dispatch_sync_f(wb_queue, block, wb_dispatch_execute);
  } else {
    dispatch_async_f(wb_queue, block, wb_dispatch_execute);
  }
}

@end
#endif
@implementation _WBSerialQueueBlock

@synthesize target = wb_target;
@synthesize action = wb_action;
@synthesize argument = wb_argument;

- (void)dealloc {
  [wb_argument release];
  [wb_target release];
  [super dealloc];
}


@end
