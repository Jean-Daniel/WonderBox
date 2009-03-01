/*
 *  WBSingleton.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

/* Usage:

@interface Foo : NSObject {
}

@end

WBSingleton(Foo, sharedFoo);

@implemetation Foo

your methods…

@end

*/

#define WBSingletonInterface(ClassName, sharedSelector) \
\
@interface ClassName () <NSCopying> \
\
+ (ClassName*)sharedSelector; \
\
- (id)copyWithZone:(NSZone *)zone; \
\
@end

#define WBSingleton(ClassName, sharedSelector) \
 \
static ClassName *sShared##ClassName##Instance = nil; \
\
+ (ClassName*)sharedSelector { \
  if (sShared##ClassName##Instance) \
    return sShared##ClassName##Instance; \
  @synchronized(self) { \
    if (!sShared##ClassName##Instance) { \
      [[self alloc] init]; \
    } \
  } \
  return sShared##ClassName##Instance; \
} \
\
/* -------------- Singleton override -------------- */ \
+ (id)allocWithZone:(NSZone *)zone { \
  if (sShared##ClassName##Instance) \
    return sShared##ClassName##Instance; \
  @synchronized(self) { \
    if (!sShared##ClassName##Instance) { \
      sShared##ClassName##Instance = [super allocWithZone:zone]; \
    } \
  } \
  return sShared##ClassName##Instance; \
} \
- (id)copyWithZone:(NSZone *)zone { \
  return self; \
} \
\
- (id)retain { \
  return self; \
} \
- (NSUInteger)retainCount { \
  return NSUIntegerMax;  /* denotes an object that cannot be released */ \
} \
- (void)release { \
  /* do nothing */ \
} \
- (id)autorelease { \
  return self; \
}
