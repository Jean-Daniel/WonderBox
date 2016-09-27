/*
 *  WBObjCRuntime.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <objc/objc-runtime.h> // must be before WBObjCRuntime.h

#include <WonderBox/WBObjCRuntime.h>

#pragma mark Objective-C Runtime

WB_INLINE
BOOL __WBRuntimeIsSubclass(Class cls, Class parent) {
  assert(cls && "invalid parameter");
  Class super = cls;
  do {
    if (super == parent)
      return YES;
  } while ((super = class_getSuperclass(super)));
  return NO;
}

Class WBRuntimeSetObjectClass(id anObject, Class newClass) {
  return object_setClass(anObject, newClass);
}

/* Does not check super class */
BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL sel) {
  unsigned int count = 0;
  Method *methods = class_copyMethodList(cls, &count);
  if (methods) {
    while(count-- > 0) {
      Method method = methods[count];
      if (method_getName(method) == sel) {
        free(methods);
        return YES;
      }
    }
    free(methods);
  }
  return NO;
}

CFArrayRef WBRuntimeCopySubclasses(Class parent, BOOL strict) {
  int numClasses;
  Class *classes = NULL;
  numClasses = objc_getClassList(NULL, 0);
  CFMutableArrayRef result = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL); // no need to managed memory for Class
  if (numClasses > 0 && (size_t)numClasses < SIZE_T_MAX / sizeof(Class)) {
    classes = (Class *)malloc(sizeof(Class) * (size_t)numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    for (int idx = 0; idx < numClasses; idx++) {
      Class cls = classes[idx];
      if (strict) {
        // If is direct subclass
        if (class_getSuperclass(cls) == parent)
          CFArrayAppendValue(result, cls);
      } else if (parent != cls && __WBRuntimeIsSubclass(cls, parent)) {
        CFArrayAppendValue(result, cls);
      }
    }
    free(classes);
  }
  return result;
}

/* Method Swizzling */
static
void _WBRuntimeExchangeMethods(Class class, SEL orig, SEL new, bool instance) {
  Method (*getMethod)(Class, SEL) = instance ? class_getInstanceMethod : class_getClassMethod;
  Method m1 = getMethod(class, orig);
  assert(m1 != NULL);
  // make sure the class implements the source method and not it's superclass
  assert(getMethod(class_getSuperclass(class), orig) != m1);

  Method m2 = getMethod(class, new);
  assert(m2 != NULL);
  method_exchangeImplementations(m1, m2);
}

void WBRuntimeExchangeClassMethods(Class cls, SEL orig, SEL replace) {
  _WBRuntimeExchangeMethods(cls, orig, replace, false);
}

void WBRuntimeExchangeInstanceMethods(Class cls, SEL orig, SEL replace) {
  _WBRuntimeExchangeMethods(cls, orig, replace, true);
}
static
IMP _WBRuntimeSetMethodImplementation(Class cls, SEL sel, IMP addr, bool instance) {
  IMP previous = NULL;
  Method method = instance ? class_getInstanceMethod(cls, sel) : class_getClassMethod(cls, sel);
  if (method)
    previous = method_setImplementation(method, addr);
  return previous;
}

IMP WBRuntimeSetClassMethodImplementation(Class base, SEL selector, IMP placeholder) {
  return _WBRuntimeSetMethodImplementation(base, selector, placeholder, false);
}
IMP WBRuntimeSetInstanceMethodImplementation(Class base, SEL selector, IMP placeholder) {
  return _WBRuntimeSetMethodImplementation(base, selector, placeholder, true);
}

BOOL WBRuntimeObjectImplementsSelector(id object, SEL method) {
  return WBRuntimeInstanceImplementsSelector(object_getClass(object), method);
}

BOOL WBRuntimeClassImplementsSelector(Class cls, SEL method) {
  return WBRuntimeInstanceImplementsSelector(object_getClass((id)cls), method);
}

bool WBRuntimeObjectIsKindOfClass(id obj, Class parent) {
  return __WBRuntimeIsSubclass(object_getClass(obj), parent);
}

bool WBRuntimeObjectIsMemberOfClass(id obj, Class parent) {
  return object_getClass(obj) == parent;
}

bool WBRuntimeClassIsSubclassOfClass(Class cls, Class parent) {
  return __WBRuntimeIsSubclass(cls, parent);
}
