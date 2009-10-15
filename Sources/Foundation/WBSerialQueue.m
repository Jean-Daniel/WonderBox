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

@implementation WBSerialQueue

- (id)init {
  if (self = [super init]) {
    [self setMaxConcurrentOperationCount:1];
    if ([self respondsToSelector:@selector(setName:)])
      [self setName:@"org.shadowlab.serial-queue"];
  }
  return self;
}

- (void)dealloc {
  [wb_last release];
  [super dealloc];
}

- (void)addOperation:(NSOperation *)op {
  @synchronized(self) {
    if (wb_last) {
      [wb_last removeObserver:self forKeyPath:@"isFinished"];
      [op addDependency:wb_last];
    }
    WBSetterRetain(&wb_last, op);
    [op addObserver:self forKeyPath:@"isFinished" options:0 context:WBSerialQueue.class];
  }
  [super addOperation:op];
}

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg {
  NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:target selector:sel object:arg];
  [self addOperation:op];
  [op release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == WBSerialQueue.class) {
    @synchronized(self) {
      if (wb_last == object) {
        [wb_last removeObserver:self forKeyPath:@"isFinished"];
        WBSetterRetain(&wb_last, nil);
      }
    }
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

@end
