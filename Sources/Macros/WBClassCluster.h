/*
 *  WBClassCluster.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
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
       self = [[MyYopsClass allocWithZone:[self zone]] initWithType:type];
       break;
     case 'flop':
       self = [[MyFlopClass allocWithZone:[self zone]] init];
       break;
     default:
       self = nil;
   }
   return self;
 }
 @end

 MyFlopClass and MyYopsClass must be MyClass subclass, else it would not be a class cluster.
*/

#define WBClassCluster(classname)    \
  WBClassClusterPlaceHolder(classname, classname, classname) \
  WBClassClusterImplementation(classname, classname, classname)

/* Variant which does not override classForCoder */
#define WBClassClusterNoClassForCoder(classname)    \
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

// MARK: Names
#define WBClusterPlaceholder(classname)         classname##ClusterPlaceholder
#define WBClusterDefaultPlaceholder(classname)  classname##DefaultClusterPlaceholder

// MARK: -
// MARK: Internal
#if __has_feature(objc_arc)
  #define __WBInternalSingleton
#else
  #define __WBInternalSingleton \
            - (id)init { return nil; } \
            - (id)copyWithZone:(NSZone *)zone { return self; }  \
            - (id)retain { return self; } \
            - (NSUInteger)retainCount { return NSUIntegerMax; } \
            - (oneway void)release { /* do nothing */ }         \
            - (id)autorelease { return self; }
#endif

#define _WBInternalClassClusterPlaceHolder(superclass, placeholderclass, defaultplaceholder) \
  @interface placeholderclass : superclass \
  @end \
  static placeholderclass *defaultplaceholder = nil; \
  @implementation placeholderclass \
  + (void)initialize { \
    if ([placeholderclass class] == self) \
      defaultplaceholder = [self allocWithZone:nil]; \
  } \
  __WBInternalSingleton \
  @end

#define _WBInternalClassClusterImplementation(classname, placeholderclass, defaultplaceholder) \
  @implementation classname (WBClassCluster) \
  + (id)allocWithZone:(NSZone *)zone { \
    if ([classname class] == self)     \
        return defaultplaceholder;     \
    return [super allocWithZone:zone]; \
  } \
  @end

#define _WBInternalClassForCoder(classname) \
  @implementation classname (WBClusterClassForCoder) \
  - (Class)classForCoder { return [classname class]; } \
  @end
