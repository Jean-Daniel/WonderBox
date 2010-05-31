/*
 *  WBObjCRuntime.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBObjCRuntime.h)

#include <objc/objc-runtime.h>

#pragma mark Objective-C Runtime

static
BOOL _WBRuntimeInstanceImplementsSelector(Class cls, SEL sel) {
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

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5

WB_INLINE
BOOL __WBRuntimeIsSubclass(Class cls, Class parent) {
  NSCParameterAssert(cls);
  Class super = cls;
  do {
    if (super == parent)
      return YES;
  } while ((super = class_getSuperclass(super)));
  return NO;
}

WB_INLINE
BOOL __WBRuntimeIsDirectSubclass(Class cls, Class parent) {
	return class_getSuperclass(cls) == parent;
}

WB_INLINE
void __WBRuntimeExchangeMethods(Method m1, Method m2) {
  method_exchangeImplementations(m1, m2);
}

WB_INLINE
IMP __WBRuntimeSetMethodImplementation(Method method, IMP addr) {
	return method_setImplementation(method, addr);
}

WB_INLINE
Class __WBRuntimeGetMetaClass(Class cls) {
	return object_getClass(cls);
}

Class WBRuntimeSetObjectClass(id anObject, Class newClass) {
	return object_setClass(anObject, newClass);
}

/* Does not check super class */
BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method) {
	return _WBRuntimeInstanceImplementsSelector(cls, method);
}

#else

WB_INLINE
BOOL __WBRuntimeIsSubclass(Class cls, Class parent) {
  NSCParameterAssert(cls);
  Class super = cls;
  do {
    if (super == parent)
      return YES;
  } while (super = super->super_class);
  return NO;
}

WB_INLINE
BOOL __WBRuntimeIsDirectSubclass(Class cls, Class parent) {
	return cls->super_class == parent;
}

WB_INLINE
void __WBRuntimeExchangeMethods(Method m1, Method m2) {
  if (method_exchangeImplementations) {
		method_exchangeImplementations(m1, m2);
	} else {
		IMP imp = m1->method_imp;
		m1->method_imp = m2->method_imp;
		m2->method_imp = imp;
	}
}

WB_INLINE
IMP __WBRuntimeSetMethodImplementation(Method method, IMP addr) {
	if (method_setImplementation)
		return method_setImplementation(method, addr);
	
	IMP previous = method->method_imp;
	method->method_imp = addr;
	return previous;
}

WB_INLINE
Class __WBRuntimeGetMetaClass(Class cls) {
	return object_getClass ? object_getClass(cls) : cls->isa;
}

Class WBRuntimeSetObjectClass(id anObject, Class newClass) {
	if (object_setClass)
		return object_setClass(anObject, newClass);
	
	/* manual isa swizzling */
	Class previous = anObject->isa;
	anObject->isa = newClass;
	return previous;
}

BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method) {
	/* if leopard runtime available */
	if (class_copyMethodList)
		return _WBRuntimeInstanceImplementsSelector(cls, method);
	
	void *iterator = 0;
	struct objc_method_list *methodList;
	//
	// Each call to class_nextMethodList returns one methodList
	//
	while(methodList = class_nextMethodList(cls, &iterator)) {
		int count = methodList->method_count;
		while (count-- > 0) {
			if (methodList->method_list[count].method_name == method)
				return YES;
		}
	}
	return NO;
}

#endif

NSArray *WBRuntimeGetSubclasses(Class parent, BOOL strict) {
	int numClasses;
	Class *classes = NULL;
	numClasses = objc_getClassList(NULL, 0);
	NSMutableArray *result = [NSMutableArray array];
	if (numClasses > 0 ) {
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
		for (int idx = 0; idx < numClasses; idx++) {
			Class cls = classes[idx];
			if (strict) {
				if (__WBRuntimeIsDirectSubclass(cls, parent))
					[result addObject:cls];
			} else if (parent != cls && __WBRuntimeIsSubclass(cls, parent)) {
				[result addObject:cls];
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
  check(m1 != NULL);
  // make sure the class implements the source method and not it's superclass
  check(getMethod(class_getSuperclass(class), orig) != m1);

  Method m2 = getMethod(class, new);
  check(m2 != NULL);
	return __WBRuntimeExchangeMethods(m1, m2);
}

void WBRuntimeExchangeClassMethods(Class cls, SEL orig, SEL replace) {
	return _WBRuntimeExchangeMethods(cls, orig, replace, false);
}

void WBRuntimeExchangeInstanceMethods(Class cls, SEL orig, SEL replace) {
	return _WBRuntimeExchangeMethods(cls, orig, replace, true);
}
static
IMP _WBRuntimeSetMethodImplementation(Class cls, SEL sel, IMP addr, bool instance) {
	IMP previous = NULL;
  Method method = instance ? class_getInstanceMethod(cls, sel) : class_getClassMethod(cls, sel);
  if (method)
		previous = __WBRuntimeSetMethodImplementation(method, addr);
  return previous;
}

IMP WBRuntimeSetClassMethodImplementation(Class base, SEL selector, IMP placeholder) {
	return _WBRuntimeSetMethodImplementation(base, selector, placeholder, false);
}
IMP WBRuntimeSetInstanceMethodImplementation(Class base, SEL selector, IMP placeholder) {
	return _WBRuntimeSetMethodImplementation(base, selector, placeholder, true);	
}

BOOL WBRuntimeObjectImplementsSelector(id object, SEL method) {
	return WBRuntimeInstanceImplementsSelector([object class], method);
}

BOOL WBRuntimeClassImplementsSelector(Class cls, SEL method) {
	return WBRuntimeInstanceImplementsSelector(__WBRuntimeGetMetaClass(cls), method);
}
