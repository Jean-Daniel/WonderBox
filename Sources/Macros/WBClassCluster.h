/*
 *  WBClassCluster.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

/*
 Class initializer must be implemented in a categorie of WBClusterPlaceholder(classname).
 For example, if you have MyClass class, you should declare:
 
 @interface MyClass 
 - (id)initWithType:(OSType)type;
 @end
 
 WBClassCluster(MyClass)
 
 @implementation WBClusterPlaceholder(MyClass) (SomeCategorie)
 - (id)initWithType:(OSType)type {
   switch (type) {
     case 'yops':
     case 'spoy':
       self = [[MyYopsClass alloc] initWithType:type];
       break;
     case 'flop':
       self = [[MyFlopClass alloc] init];
       break;
     default:
       self = nil;
   }
   return self;
 }
 @end

 MyFlopClass and MyYopsClass must be MyClass subclass, else it would not be a class cluster.
*/

#define WBClassCluster(classname)		\
WBClassClusterPlaceHolder(classname, classname, classname, classname) \
WBClassClusterImplementation(classname, classname, classname, classname)

#define WBClassClusterPlaceHolder(classname, placeholderPrefix, defaultPlaceholderPrefix, zonestablePrefix) \
	_WBInternalClassClusterPlaceHolder(classname, \
                                     WBClusterPlaceholder(placeholderPrefix), \
                                     WBClusterDefaultPlaceholder(defaultPlaceholderPrefix), \
                                     WBClusterZoneTable(zonestablePrefix))

#define WBClassClusterImplementation(classname, placeholderPrefix, defaultPlaceholderPrefix, zonestablePrefix) \
_WBInternalClassClusterImplementation(classname, \
                                      WBClusterPlaceholder(placeholderPrefix), \
                                      WBClusterDefaultPlaceholder(defaultPlaceholderPrefix), \
                                      WBClusterZoneTable(zonestablePrefix))

#define WBClusterZoneTable(classname)           classname##ClusterPlaceholderZones
#define WBClusterPlaceholder(classname)         classname##ClusterPlaceholder
#define WBClusterDefaultPlaceholder(classname)  classname##DefaultClusterPlaceholder

#define _WBInternalClassClusterPlaceHolder(superclass, placeholderclass, defaultplaceholder, zonestable) \
@interface placeholderclass : superclass { \
} \
@end \
\
static NSMapTable *zonestable = nil; \
static placeholderclass *defaultplaceholder = nil; \
\
@implementation placeholderclass \
\
+ (void)load { \
  if (!zonestable) { \
    zonestable = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, \
                                  NSNonRetainedObjectMapValueCallBacks, 0); \
    defaultplaceholder = (id)NSAllocateObject(self, 0, nil); \
  } \
} \
\
- (id)init { \
  return nil; \
} \
\
/* -------------- Constant Instance -------------- */ \
- (id)copyWithZone:(NSZone *)zone { \
  return self; \
} \
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
} \
\
@end

#define _WBInternalClassClusterImplementation(classname, placeholderclass, defaultplaceholder, zonestable) \
@implementation classname (WBClassCluster) \
\
+ (id)allocWithZone:(NSZone *)zone { \
  if (self == [classname class]) { \
    /* \
     * For a constant string, we return a placeholder object that can \
     * be converted to a real object when its initialisation method \
     * is called. \
     */ \
    if (zone == NULL || zone == NSDefaultMallocZone()) { \
      /* \
       * As a special case, we can return a placeholder for a string \
       * in the default malloc zone extremely efficiently. \
       */ \
      return defaultplaceholder; \
	  } else { \
      id obj; \
      /* \
       * For anything other than the default zone, we need to \
       * locate the correct placeholder in the (lock protected) \
       * table of placeholders. \
       */ \
      @synchronized(self) { \
          obj = (id)NSMapGet(zonestable, (void*)zone); \
          if (obj == nil) { \
            /* \
             * There is no placeholder object for this zone, so we \
             * create a new one and use that. \
             */ \
            obj = (id)NSAllocateObject([placeholderclass class], 0, zone); \
            NSMapInsert(zonestable, (void*)zone, (void*)obj); \
          } \
        } \
      return obj; \
    } \
  } else { \
    /* \
     * For user provided strings, we simply allocate an object of \
     * the given class. \
     */ \
    return [super allocWithZone:zone]; \
  } \
} \
\
\
- (Class)classForCoder { \
  return [classname class]; \
} \
\
@end


