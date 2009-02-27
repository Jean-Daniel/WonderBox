/*
 *  WBScope.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

// from http://www.kickingbear.com

#define WBScopeReleased __attribute__((cleanup($wb_scopeReleaseObject)))
#define WBScopeCFReleased __attribute__((cleanup($wb_scopeCFReleaseObject)))

#define WBScopeAutoreleasePool() \
	NSAutoreleasePool *$wb_autoreleasePool##__LINE__ __attribute__((cleanup($wb_scopeDrainAutoreleasePool))) = [[NSAutoreleasePool alloc] init]

/* Internal functions */
static __inline__
void $wb_scopeReleaseObject(id *scopeReleasedObject) {
  [*scopeReleasedObject release];
}

static __inline__
void $wb_scopeCFReleaseObject(id *scopeReleasedObject) {
  if (*scopeReleasedObject) 
    CFRelease(*scopeReleasedObject);
}

static __inline__
void $wb_scopeDrainAutoreleasePool(NSAutoreleasePool **pool) {
  WBAutoreleasePoolDrain(*pool);
}
