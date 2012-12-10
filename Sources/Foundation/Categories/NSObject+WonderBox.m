/*
 *  NSObject+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSObject+WonderBox.h>

@implementation NSObject (WonderBox)

- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject {
  [self performSelectorASAP:aSelector withObject:anObject order:0 inModes:nil];
}
- (void)cancelPerformSelectorASAP:(SEL)aSelector withObject:(id)anObject {
  [[NSRunLoop currentRunLoop] cancelPerformSelector:aSelector target:self argument:anObject];
}
- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject order:(NSUInteger)anOrder inModes:(NSArray *)theModes {
  [[NSRunLoop currentRunLoop] performSelector:aSelector
                                       target:self
                                     argument:anObject
                                        order:anOrder
                                        modes:theModes ? : [NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

@end
