/*
 *  NSInvocation+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSInvocation+WonderBox.h>

@implementation NSInvocation (WBExtensions)

+ (id)invocationWithTarget:(id)target selector:(SEL)action {
  if (![target respondsToSelector:action])
		SPXThrowException(NSInvalidArgumentException, @"%@ does not responds to selector %@",
										 target, NSStringFromSelector(action));

  NSMethodSignature *sign = [target methodSignatureForSelector:action];
  NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:sign];
  [invoc setTarget:target];
  [invoc setSelector:action];
  return invoc;
}

@end
