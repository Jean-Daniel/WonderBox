/*
 *  WBAppleRemote.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <IOKit/hid/IOHIDBase.h>

typedef enum {
  kWBAppleRemoteButtonMenu = 0,
  kWBAppleRemoteButtonSelect,
  
  kWBAppleRemoteButtonUp,
  kWBAppleRemoteButtonDown,
  kWBAppleRemoteButtonLeft,
  kWBAppleRemoteButtonRight,
  /* others */
  kWBAppleRemoteButtonRewind,
  kWBAppleRemoteButtonFastForward,
} WBAppleRemoteButton;

#define kWBAppleRemoteButtonCount 8

@protocol WBAppleRemoteListener;
@interface WBAppleRemote : NSObject {
@private
  NSMutableArray *wb_listeners;
  
@protected
  IOHIDElementCookie wb_cookies[kWBAppleRemoteButtonCount];
}

+ (BOOL)isAvailable;

- (id)initExclusive:(BOOL)isExclusive;

- (void)addListener:(NSObject<WBAppleRemoteListener> *)aListener;
- (void)removeListener:(NSObject<WBAppleRemoteListener> *)aListener;

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop;
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop;

@end

@protocol WBAppleRemoteListener

@required
- (void)remoteButtonDown:(WBAppleRemoteButton)aButton;
- (void)remoteButtonUp:(WBAppleRemoteButton)aButton;

@end
