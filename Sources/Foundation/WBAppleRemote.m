/*
 *  WBAppleRemote.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBAppleRemote.h>

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>

WB_INLINE
NSString *__WBAppleRemoteButtonName(WBAppleRemoteButton button) {
  switch (button) {
    case kWBAppleRemoteButtonMenu: return @"kWBAppleRemoteButtonMenu";
    case kWBAppleRemoteButtonSelect: return @"kWBAppleRemoteButtonSelect";
    case kWBAppleRemoteButtonUp: return @"kWBAppleRemoteButtonUp";
    case kWBAppleRemoteButtonDown: return @"kWBAppleRemoteButtonDown";
    case kWBAppleRemoteButtonLeft: return @"kWBAppleRemoteButtonLeft";
    case kWBAppleRemoteButtonRight: return @"kWBAppleRemoteButtonRight";
      /* others */
    case kWBAppleRemoteButtonRewind: return @"kWBAppleRemoteButtonRewind";
    case kWBAppleRemoteButtonFastForward: return @"kWBAppleRemoteButtonFastForward";
  }
  return @"<undefined>";
}

@interface WBAppleRemote ()

- (id)initWithService:(io_service_t)service options:(IOOptionBits)options;

- (void)handleEvent:(IOHIDElementCookie)aCookie value:(CFIndex)aValue;

@end

static
void _WBAppleRemoteInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
  IOHIDElementRef element = IOHIDValueGetElement(value);
  [(WBAppleRemote *)context handleEvent:IOHIDElementGetCookie(element)
                                  value:IOHIDValueGetIntegerValue(value)];
}

@implementation WBAppleRemote

+ (BOOL)isAvailable {
  BOOL result = NO;
  CFMutableDictionaryRef hidMatchDictionary = IOServiceNameMatching("AppleIRController");
  io_service_t hidService = IOServiceGetMatchingService(kIOMasterPortDefault, hidMatchDictionary);
  if (hidService) {
    result = YES;
    IOObjectRelease(hidService);
  }

  return result;
}

- (id)initExclusive:(BOOL)isExclusive {
  CFMutableDictionaryRef hidMatchDictionary = IOServiceNameMatching("AppleIRController");
  io_service_t hidService = IOServiceGetMatchingService(kIOMasterPortDefault, hidMatchDictionary);
  if (!hidService) {
    spx_log_warning("%s", "Apple Infrared Remote not found.");
    [self release];
    return nil;
  }

  if (self = [self initWithService:hidService options:isExclusive ? kIOHIDOptionsTypeSeizeDevice : 0]) {
    wb_listeners = [[NSMutableArray alloc] init];
  }
  IOObjectRelease(hidService);
  return self;
}
- (id)initWithService:(io_service_t)aService options:(IOOptionBits)options {
  if (self = [super init]) {
    wb_device = IOHIDDeviceCreate(kCFAllocatorDefault, aService);
    if (!wb_device) {
      spx_log_warning("Failed to create Apple Remote device");
      [self release];
      return nil;
    }
    IOReturn result = IOHIDDeviceOpen(wb_device, options); // kIOHIDOptionsTypeSeizeDevice
    if (kIOReturnSuccess != result) {
      spx_log_warning("Error while opening remote: %s", mach_error_string(result));
      CFRelease(wb_device);
      wb_device = NULL;
      [self release];
      return nil;
    }

    //    CFTypeRef keys[] = { CFSTR(kIOHIDElementUsagePageKey), CFSTR(kIOHIDElementTypeKey) };
    //    CFTypeRef values[] = {WBInteger(kHIDPage_GenericDesktop), WBInteger(kIOHIDElementTypeInput_Button)};
    //    CFDictionaryRef filter = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 2, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    //    IOHIDDeviceSetInputValueMatching(wb_device, filter);
    //    CFRelease(filter);

    IOHIDDeviceRegisterInputValueCallback(wb_device, _WBAppleRemoteInputValueCallback, self);

    CFArrayRef elements = IOHIDDeviceCopyMatchingElements(wb_device, NULL, 0);
    if (elements) {
      for (CFIndex i = 0; i < CFArrayGetCount(elements); i++) {
        IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
        if (IOHIDElementGetUsagePage(element) == kHIDPage_GenericDesktop) {
          switch (IOHIDElementGetUsage(element)) {
            case kHIDUsage_GD_SystemAppMenu:
              wb_cookies[kWBAppleRemoteButtonMenu] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_GD_SystemMenu:
              wb_cookies[kWBAppleRemoteButtonSelect] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_GD_SystemMenuRight:
              wb_cookies[kWBAppleRemoteButtonRight] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_GD_SystemMenuLeft:
              wb_cookies[kWBAppleRemoteButtonLeft] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_GD_SystemMenuUp:
              wb_cookies[kWBAppleRemoteButtonUp] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_GD_SystemMenuDown:
              wb_cookies[kWBAppleRemoteButtonDown] = IOHIDElementGetCookie(element);
              break;
          }
        } else if (IOHIDElementGetUsagePage(element) == kHIDPage_Consumer) {
          switch (IOHIDElementGetUsage(element)) {
            case kHIDUsage_Csmr_Rewind:
              wb_cookies[kWBAppleRemoteButtonRewind] = IOHIDElementGetCookie(element);
              break;
            case kHIDUsage_Csmr_FastForward:
              wb_cookies[kWBAppleRemoteButtonFastForward] = IOHIDElementGetCookie(element);
              break;
              //          case kHIDUsage_Csmr_Menu:
              //            wb_cookies[kWBAppleRemoteButtonApplicationMenu] = IOHIDElementGetCookie(element);
              // break;
              //          default:
              //            SPXDebug(@"ignore consumer: %lx, %lx", IOHIDElementGetCookie(element), IOHIDElementGetUsage(element));
          }
        }
      }
      CFRelease(elements);
    }
  }
  return self;
}

- (void)dealloc {
  if (wb_device) {
    IOHIDDeviceUnscheduleFromRunLoop(wb_device, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    IOHIDDeviceClose(wb_device, 0);
    CFRelease(wb_device);
    wb_device = NULL;
  }
  [wb_listeners release];
  spx_dealloc();
}

#pragma mark -
- (void)handleEvent:(IOHIDElementCookie)aCookie value:(CFIndex)aValue {
  for (NSUInteger idx = 0; idx < kWBAppleRemoteButtonCount; idx++) {
    if (wb_cookies[idx] == aCookie) {
      //SPXDebug(@"handle event: %@", __WBAppleRemoteButtonName(idx));
      for (NSUInteger jdx = 0, count = [wb_listeners count]; jdx < count; jdx++) {
        if (aValue)
          [[wb_listeners objectAtIndex:jdx] remoteButtonDown:idx];
        else
          [[wb_listeners objectAtIndex:jdx] remoteButtonUp:idx];
      }
      return;
    }
  }
}

- (void)addListener:(NSObject<WBAppleRemoteListener> *)aListener {
  NSParameterAssert(NSNotFound == [wb_listeners indexOfObjectIdenticalTo:aListener]);
  [wb_listeners addObject:aListener];
//  if ([wb_listeners count] == 1)
//    [self start];
}

- (void)removeListener:(NSObject<WBAppleRemoteListener> *)aListener {
  NSParameterAssert(NSNotFound != [wb_listeners indexOfObjectIdenticalTo:aListener]);
  [wb_listeners removeObjectIdenticalTo:aListener];
//  if ([wb_listeners count] == 0)
//    [self uns];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_device)
    IOHIDDeviceScheduleWithRunLoop(wb_device, [aRunLoop getCFRunLoop], kCFRunLoopCommonModes);
}
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_device)
    IOHIDDeviceUnscheduleFromRunLoop(wb_device, [aRunLoop getCFRunLoop], kCFRunLoopCommonModes);
}

@end
