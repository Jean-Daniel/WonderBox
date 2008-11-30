/*
 *  WBCFContext.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#if !defined(__WBCFCONTEXT_H)
#define __WBCFCONTEXT_H 1
/*!
@header ShadowCFContext
 @abstract Provide some CallBack Wrapper to pass NSObject in CFContext
 */
#if defined(__WB_OBJC__)
WB_EXPORT
const void *WBCBNSObjectRetain(const void *obj);
WB_EXPORT
void WBCBNSObjectRelease(const void *obj);

WB_EXPORT
const void *WBCBNSObjectRetainWithAllocator(CFAllocatorRef allocator, const void *obj);
WB_EXPORT
void WBCBNSObjectReleaseWithAllocator(CFAllocatorRef allocator, const void *obj);

WB_EXPORT
CFHashCode WBCBNSObjectHash(const void *value);
WB_EXPORT
CFStringRef WBCBNSObjectCopyDescription(const void *obj);
WB_EXPORT
Boolean WBCBNSObjectEqual(const void *value1, const void *value2);
#endif

#pragma mark Set
WB_EXPORT
const CFSetCallBacks kWBPointerSetCallBacks;
WB_EXPORT
const CFSetCallBacks kWBIntegerSetCallBacks;
#if defined(__WB_OBJC__)
WB_EXPORT
const CFSetCallBacks kWBNSObjectSetCallBacks;
#endif

#pragma mark Array
WB_EXPORT
const CFArrayCallBacks kWBPointerArrayCallBacks;
WB_EXPORT
const CFArrayCallBacks kWBIntegerArrayCallBacks;
#if defined(__WB_OBJC__)
WB_EXPORT
const CFArrayCallBacks kWBNSObjectArrayCallBacks;
#endif

#pragma mark Dictionary
WB_EXPORT
const CFDictionaryKeyCallBacks kWBPointerDictionaryKeyCallBacks;
WB_EXPORT
const CFDictionaryValueCallBacks kWBPointerDictionaryValueCallBacks;

WB_EXPORT
const CFDictionaryKeyCallBacks kWBIntegerDictionaryKeyCallBacks;
WB_EXPORT
const CFDictionaryValueCallBacks kWBIntegerDictionaryValueCallBacks;

#if defined(__WB_OBJC__)
WB_EXPORT
const CFDictionaryKeyCallBacks kWBNSObjectDictionaryKeyCallBacks;
WB_EXPORT
const CFDictionaryValueCallBacks kWBNSObjectDictionaryValueCallBacks;
#endif

#endif /* __WBCFCONTEXT_H */
