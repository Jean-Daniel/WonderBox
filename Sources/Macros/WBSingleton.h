/*
 *  WBSingleton.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
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
