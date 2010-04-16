/*
 *  NSObject+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSObject+WonderBox.h)

@interface WBInternalClass(DelayedAction) : NSObject {
@private
  id _target;
  SEL _action;
  id _argument;
}

@property SEL action;

@property(retain, nonatomic) id target;
@property(retain, nonatomic) id argument;

- (void)execute;
- (void)invalidate;

@end

// TODO: implements cancel.
@implementation NSObject (WonderBox)

static
void _WBCFRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
  WBInternalClass(DelayedAction) *action = (id)info;
  [action execute];
  [action invalidate];
}

- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject {
  [self performSelectorASAP:aSelector withObject:anObject inModes:NSDefaultRunLoopMode];
}

- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject inModes:(NSString *)aMode {
  WBInternalClass(DelayedAction) *action = [[WBInternalClass(DelayedAction) alloc] init];
  action.target = self;
  action.action = aSelector;
  action.argument = anObject;

  CFRunLoopObserverContext ctxt = {
    .version = 0,
    .info = action,
    .retain = CFRetain,
    .release = CFRelease,
    .copyDescription = CFCopyDescription,
  };
  CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, 
                                                          false, 0, _WBCFRunLoopObserver, &ctxt);  
  CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, WBNSToCFString(aMode));
  CFRelease(observer);
  [action release];
}

@end

@implementation WBInternalClass(DelayedAction)

@synthesize target = _target;
@synthesize action = _action;
@synthesize argument = _argument;

- (void)dealloc {
  [_argument release];
  [_target release];
  [super dealloc];
}

- (void)execute {
  if (_target)
    [_target performSelector:_action withObject:_argument];
}

- (void)invalidate {
  [_argument release];
  _argument = nil;
  [_target release];
  _target = nil;
}

@end

