/*
 *  WBForwarding.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#define WBForwarding(classname, superclass, ivar) \
\
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector { \
  return [super methodSignatureForSelector:aSelector] ? : [ivar methodSignatureForSelector:aSelector]; \
} \
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector { \
  return [super methodSignatureForSelector:aSelector] ? : [superclass methodSignatureForSelector:aSelector]; \
} \
 \
- (void)forwardInvocation:(NSInvocation *)anInvocation { \
  if ([ivar respondsToSelector:[anInvocation selector]]) { \
    [anInvocation invokeWithTarget:ivar]; \
  } else { \
    [super forwardInvocation:anInvocation]; \
  } \
} \
/* Leopard fast forward path */ \
- (id)forwardingTargetForSelector:(SEL)sel { \
  if ([ivar respondsToSelector:sel]) \
    return ivar; \
  return [super forwardingTargetForSelector:sel]; \
} \
- (BOOL)respondsToSelector:(SEL)aSelector { \
  return [super respondsToSelector:aSelector] ? YES : [ivar respondsToSelector:aSelector]; \
} \
+ (BOOL)instancesRespondToSelector:(SEL)aSelector { \
  return [super instancesRespondToSelector:aSelector] ? YES : [superclass instancesRespondToSelector:aSelector]; \
} \
 \
- (IMP)methodForSelector:(SEL)aSelector { \
  return [super respondsToSelector:aSelector] ? [super methodForSelector:aSelector] : [ivar methodForSelector:aSelector]; \
} \
+ (IMP)instanceMethodForSelector:(SEL)aSelector { \
  return [super instancesRespondToSelector:aSelector] ? [super instanceMethodForSelector:aSelector] : [superclass instanceMethodForSelector:aSelector]; \
} \
 \
- (BOOL)conformsToProtocol:(Protocol *)aProtocol { \
  return [super conformsToProtocol:aProtocol] ? YES : [ivar conformsToProtocol:aProtocol]; \
} \
 \
- (BOOL)isKindOfClass:(Class)aClass { \
  return [super isKindOfClass:aClass] ? YES : [ivar isKindOfClass:aClass]; \
} \
+ (BOOL)isSubclassOfClass:(Class)aClass { \
  return [super isSubclassOfClass:aClass] ? YES : [superclass isSubclassOfClass:aClass]; \
} \
 \
- (id)valueForUndefinedKey:(NSString *)key { \
  return [ivar valueForKey:key]; \
} \
- (void)setValue:(id)value forUndefinedKey:(NSString *)key { \
  [ivar setValue:value forKey:key]; \
}

/* Missing method from leopard header */
@interface NSObject (FastForwardingPath)
- (id)forwardingTargetForSelector:(SEL)sel;
@end
