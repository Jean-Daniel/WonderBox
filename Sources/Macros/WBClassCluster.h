/*
 *  WBClassCluster.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2011 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

/*
 Usage:

 @interface MyClass
 - (id)initWithType:(OSType)type;
 @end

 WBClassCluster(MyClass)

 @interface WBClusterPlaceholder(MyClass) ()
  - (id)initWithType:(OSType)type WB_CLUSTER_METHOD;
 @end

 @implementation WBClusterPlaceholder(MyClass)
 - (id)initWithType:(OSType)type {
   switch (type) {
     case 'yops':
     case 'spoy':
       return [[MyYopsClass allocWithZone:nil] initWithType:type];
     case 'flop':
       return [[MyFlopClass allocWithZone:nil] init];
   }
   return nil;
 }
 @end

 MyFlopClass and MyYopsClass must be MyClass subclass, else it would not be a class cluster.
*/

#define WBClassCluster(classname) \
  WBClassClusterPlaceHolder(classname, classname, classname) \
  WBClassClusterImplementation(classname, classname, classname)

/* Variant which does not override classForCoder */
#define WBClassClusterNoClassForCoder(classname) \
  WBClassClusterPlaceHolder(classname, classname, classname) \
  WBClassClusterImplementationNoClassForCoder(classname, classname, classname)


// Details
#define WBClassClusterPlaceHolder(classname, placeholderPrefix, defaultPlaceholderPrefix) \
  _WBInternalClassClusterPlaceHolder(classname, \
                                     WBClusterPlaceholder(placeholderPrefix), \
                                     WBClusterDefaultPlaceholder(defaultPlaceholderPrefix))

#define WBClassClusterImplementation(classname, placeholderPrefix, defaultPlaceholderPrefix) \
  _WBInternalClassClusterImplementation(classname, \
                                        WBClusterPlaceholder(placeholderPrefix), \
                                        WBClusterDefaultPlaceholder(defaultPlaceholderPrefix)) \
  _WBInternalClassForCoder(classname)

#define WBClassClusterImplementationNoClassForCoder(classname, placeholderPrefix, defaultPlaceholderPrefix) \
  _WBInternalClassClusterImplementation(classname, \
                                        WBClusterPlaceholder(placeholderPrefix), \
                                        WBClusterDefaultPlaceholder(defaultPlaceholderPrefix))

#define WB_CLUSTER_METHOD NS_METHOD_FAMILY(none) NS_RETURNS_RETAINED

// MARK: Names
#define WBClusterPlaceholder(classname)         classname##ClusterPlaceholder
#define WBClusterDefaultPlaceholder(classname)  classname##DefaultClusterPlaceholder

// MARK: -
// MARK: Internal
#if __has_feature(objc_arc)
  #define __WBInternalSingleton
#else
  #define __WBInternalSingleton \
            - (id)init { return nil; }                          \
            - (id)copyWithZone:(NSZone *)zone { return self; }  \
            - (id)retain { return self; }                       \
            - (NSUInteger)retainCount { return NSUIntegerMax; } \
            - (oneway void)release { /* do nothing */ }         \
            - (id)autorelease { return self; }
#endif

#define _WBInternalClassClusterPlaceHolder(superclass, placeholderclass, defaultplaceholder) \
  @interface placeholderclass : NSObject                    \
  @end                                                      \
  @interface placeholderclass (WBClassClusterInternal)      \
  @end                                                      \
  static placeholderclass *defaultplaceholder = nil;        \
  @implementation placeholderclass (WBClassClusterInternal) \
  + (void)initialize {                                      \
    if ([placeholderclass class] == self)                   \
      defaultplaceholder = [self allocWithZone:nil];        \
  }                                                         \
  + (id)defaultPlaceholder {                                \
    return defaultplaceholder;                              \
  }                                                         \
  __WBInternalSingleton                                     \
  @end

#define _WBInternalClassClusterImplementation(classname, placeholderclass, defaultplaceholder) \
  @implementation classname (WBClassCluster)                                 \
  + (id)allocWithZone:(NSZone *)zone {                                       \
    if ([classname class] == self)                                           \
        return defaultplaceholder ? : [placeholderclass defaultPlaceholder]; \
    return [super allocWithZone:zone];                                       \
  }                                                                          \
  @end

#define _WBInternalClassForCoder(classname) \
  @implementation classname (WBClusterClassForCoder)   \
  - (Class)classForCoder { return [classname class]; } \
  @end
