/*
 *  WBScope.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

// from http://www.kickingbear.com

#define WBScopeReleased __attribute__((cleanup($wb_scopeReleaseObject)))

// Hack to workaround the compiler strictness in type checking.
// passing something else than a CFTypeRef (like an CFStringRef for example) 
// to the cleanup function will result in a compilation error.
// We perform a stack var dereference to correctly handle case where we affect a new value
// to 'var' afterward
#define WBScopeCFReleased(type, var, value) \
	type var = value; \
	__attribute__((cleanup($wb_scopeCFReleaseObject))) CFTypeRef *__##var##__auto__ = (CFTypeRef *)&var


#define __WBScopeAutoreleasePool(line) \
  NSAutoreleasePool *$wb_autoreleasePool_##line __attribute__((cleanup($wb_scopeDrainAutoreleasePool))) = [[NSAutoreleasePool alloc] init]
// FIXME: find a cleaner way to tell the preprocessor to expand __LINE__
#define _WBScopeAutoreleasePool(line) __WBScopeAutoreleasePool(line)
#define WBScopeAutoreleasePool() _WBScopeAutoreleasePool(__LINE__)

/* Internal functions */
static __inline__
void $wb_scopeReleaseObject(id *scopeReleasedObject) {
  [*scopeReleasedObject release];
}

static __inline__
void $wb_scopeCFReleaseObject(CFTypeRef **scopeReleasedObject) {
  if (*scopeReleasedObject && **scopeReleasedObject) 
    CFRelease(**scopeReleasedObject);
}

static __inline__
void $wb_scopeDrainAutoreleasePool(NSAutoreleasePool **pool) {
  WBAutoreleasePoolDrain(*pool);
}

