/*
 *  WBCFExtension.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBCFBridge.h)

#pragma mark CFAllocatorCallCack
static
void __WBPointerReleaseWithAllocator(CFAllocatorRef allocator, const void *obj) {
  if (obj && allocator)
    CFAllocatorDeallocate(allocator, (void *)obj);
}

static
CFStringRef __WBPointerKeyCopyDescription(const void *obj) {
  return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("<%p>"), obj);
}

static
Boolean __WBPointerKeyEqual(const void *value1, const void *value2) {
  return value1 == value2;
}

static
CFHashCode __WBPointerKeyHash(const void *value) {
  return (CFHashCode)value;
}


static
CFStringRef __WBIntegerKeyCopyDescription(const void *obj) {
  return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%li"), (long)obj);
}

static
Boolean __WBIntegerKeyEqual(const void *value1, const void *value2) {
  return value1 == value2;
}

static
CFHashCode __WBIntegerKeyHash(const void *value) {
  return (CFHashCode)value;
}


#pragma mark -
#pragma mark Set
const CFSetCallBacks kWBPointerSetCallBacks = {
  0,
  NULL,
  __WBPointerReleaseWithAllocator,
  __WBPointerKeyCopyDescription,
  __WBPointerKeyEqual,
  __WBPointerKeyHash
};

const CFSetCallBacks kWBIntegerSetCallBacks = {
  0,
  NULL,
  NULL,
  __WBIntegerKeyCopyDescription,
  __WBIntegerKeyEqual,
  __WBIntegerKeyHash
};

#pragma mark -
#pragma mark Array
const CFArrayCallBacks kWBPointerArrayCallBacks = {
  0,
  NULL,
  __WBPointerReleaseWithAllocator,
  __WBPointerKeyCopyDescription,
  __WBPointerKeyEqual
};

const CFArrayCallBacks kWBIntegerArrayCallBacks = {
  0,
  NULL,
  NULL,
  __WBIntegerKeyCopyDescription,
  __WBIntegerKeyEqual,
};


#pragma mark -
#pragma mark Dictionary
const CFDictionaryKeyCallBacks kWBPointerDictionaryKeyCallBacks = {
  0,
  NULL,
  __WBPointerReleaseWithAllocator,
  __WBPointerKeyCopyDescription,
  __WBPointerKeyEqual,
  __WBPointerKeyHash
};
const CFDictionaryValueCallBacks kWBPointerDictionaryValueCallBacks = {
  0,
  NULL,
  __WBPointerReleaseWithAllocator,
  __WBPointerKeyCopyDescription,
  __WBPointerKeyEqual
};

const CFDictionaryKeyCallBacks kWBIntegerDictionaryKeyCallBacks = {
  0,
  NULL,
  NULL,
  __WBIntegerKeyCopyDescription,
  __WBIntegerKeyEqual,
  __WBIntegerKeyHash
};

const CFDictionaryValueCallBacks kWBIntegerDictionaryValueCallBacks = {
  0,
  NULL,
  NULL,
  __WBIntegerKeyCopyDescription,
  __WBIntegerKeyEqual
};

#if defined(__WB_OBJC__)
#pragma mark CFAllocatorCallCack
const void *WBCBNSObjectRetain(const void *obj) {
  return [(id)obj retain];
}

void WBCBNSObjectRelease(const void *obj) {
  [(id)obj release];
}

/* CFAllocatorRetainCallBack */
const void *WBCBNSObjectRetainWithAllocator(CFAllocatorRef allocator, const void *obj) {
  return [(id)obj retain];
}

/* CFAllocatorReleaseCallBack */
void WBCBNSObjectReleaseWithAllocator(CFAllocatorRef allocator, const void *obj) {
  [(id)obj release];
}

/* CFAllocatorCopyDescriptionCallBack */
CFStringRef WBCBNSObjectCopyDescription(const void *obj) {
  return (CFStringRef)[[(id)obj description] retain];
}

Boolean WBCBNSObjectEqual(const void *value1, const void *value2) {
  return [(id)value1 isEqual:(id)value2];
}

CFHashCode WBCBNSObjectHash(const void *value) {
  return [(id)value hash];
}

#pragma mark -
#pragma mark Set
const CFSetCallBacks kWBNSObjectSetCallBacks = {
  0,
  WBCBNSObjectRetainWithAllocator,
  WBCBNSObjectReleaseWithAllocator,
  WBCBNSObjectCopyDescription,
  WBCBNSObjectEqual,
  WBCBNSObjectHash
};

#pragma mark -
#pragma mark Array
const CFArrayCallBacks kWBNSObjectArrayCallBacks = {
  0,
  WBCBNSObjectRetainWithAllocator,
  WBCBNSObjectReleaseWithAllocator,
  WBCBNSObjectCopyDescription,
  WBCBNSObjectEqual
};

#pragma mark -
#pragma mark Dictionary
const CFDictionaryKeyCallBacks kWBNSObjectDictionaryKeyCallBacks = {
  0,
  WBCBNSObjectRetainWithAllocator,
  WBCBNSObjectReleaseWithAllocator,
  WBCBNSObjectCopyDescription,
  WBCBNSObjectEqual,
  WBCBNSObjectHash
};

const CFDictionaryValueCallBacks kWBNSObjectDictionaryValueCallBacks = {
  0,
  WBCBNSObjectRetainWithAllocator,
  WBCBNSObjectReleaseWithAllocator,
  WBCBNSObjectCopyDescription,
  WBCBNSObjectEqual
};
#endif

