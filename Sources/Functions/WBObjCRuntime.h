/*
 *  WBObjCRuntime.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WB_RUNTIME_FUNCTIONS_H)
#define __WB_RUNTIME_FUNCTIONS_H 1

#import WBHEADER(WBBase.h)

WB_EXPORT
Class WBRuntimeSetObjectClass(id anObject, Class newClass);
WB_EXPORT
CFArrayRef WBRuntimeCopySubclasses(Class parent, BOOL strict);

WB_EXPORT
bool WBRuntimeObjectIsKindOfClass(id obj, Class parent);
WB_EXPORT
bool WBRuntimeObjectIsMemberOfClass(id obj, Class parent);

WB_EXPORT
bool WBRuntimeClassIsSubclassOfClass(Class cls, Class parent);

/* Method Swizzling */
WB_EXPORT
void WBRuntimeExchangeClassMethods(Class cls, SEL orig, SEL replace);
WB_EXPORT
void WBRuntimeExchangeInstanceMethods(Class cls, SEL orig, SEL replace);

WB_EXPORT
IMP WBRuntimeSetClassMethodImplementation(Class base, SEL selector, IMP placeholder);
WB_EXPORT
IMP WBRuntimeSetInstanceMethodImplementation(Class base, SEL selector, IMP placeholder);

/* Does not check super class */
WB_EXPORT
BOOL WBRuntimeObjectImplementsSelector(id object, SEL method);
WB_EXPORT
BOOL WBRuntimeClassImplementsSelector(Class cls, SEL method);
WB_EXPORT
BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method);

#endif /* __WB_RUNTIME_FUNCTIONS_H */
