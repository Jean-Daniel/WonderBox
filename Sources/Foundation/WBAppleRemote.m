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

@interface WBAppleRemoteTiger : WBAppleRemote {
  CFRunLoopSourceRef wb_src;
  IOHIDQueueInterface **wb_queue;
  IOHIDDeviceInterface **wb_plugin;
}

@end

@interface WBAppleRemoteLeopard : WBAppleRemote {
  IOHIDDeviceRef wb_device;
}

@end

@interface WBAppleRemote (WBAppleRemoteInterface)

- (id)initWithService:(io_service_t)service options:(IOOptionBits)options;

- (void)handleEvent:(IOHIDElementCookie)aCookie value:(CFIndex)aValue;

@end

@implementation WBAppleRemote

+ (id)allocWithZone:(NSZone *)aZone {
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
  return NSAllocateObject([WBAppleRemoteLeopard class], 0, aZone);
#else
  if (!IOHIDDeviceCreate)
    return NSAllocateObject([WBAppleRemoteLeopard class], 0, aZone);
  return NSAllocateObject([WBAppleRemoteTiger class], 0, aZone);
#endif
}

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
  return [super init];
}

- (void)dealloc {
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

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop { }
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop { }

@end

#pragma mark Leopard

static
void _WBAppleRemoteInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
  IOHIDElementRef element = IOHIDValueGetElement(value);
  [(WBAppleRemoteLeopard *)context handleEvent:IOHIDElementGetCookie(element)
                                         value:IOHIDValueGetIntegerValue(value)];
}

@implementation WBAppleRemoteLeopard

- (id)initWithService:(io_service_t)service options:(IOOptionBits)options {
  if (self = [super initWithService:service options:(IOOptionBits)options]) {
    wb_device = IOHIDDeviceCreate(kCFAllocatorDefault, service);
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
  spx_dealloc();
}

#pragma mark -
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_device)
    IOHIDDeviceScheduleWithRunLoop(wb_device, [aRunLoop getCFRunLoop], kCFRunLoopCommonModes);
}
- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_device)
    IOHIDDeviceUnscheduleFromRunLoop(wb_device, [aRunLoop getCFRunLoop], kCFRunLoopCommonModes);
}

@end

#pragma mark Tiger

static
void _WBAppleRemoteTigerCallback(void *target, IOReturn result, void *refcon, void *sender) {
  HRESULT ret = 0;
  IOHIDEventStruct event;
  IOHIDQueueInterface **hqi;
  AbsoluteTime zeroTime = {0,0};

  while (!ret) {
    hqi = (IOHIDQueueInterface **)sender;
    ret = (*hqi)->getNextEvent(hqi, &event, zeroTime, 0);
    if (!ret)
      [(WBAppleRemote *)refcon handleEvent:event.elementCookie value:event.value];
  }
}

@implementation WBAppleRemoteTiger

static
bool _WBAppleRemoteTigerCreateInterface(io_object_t hidDevice, IOHIDDeviceInterface ***hdi) {
  SInt32 score = 0;
  io_name_t className;
  IOCFPlugInInterface **plugInInterface = NULL;

  IOReturn err = IOObjectGetClass(hidDevice, className);
  if (kIOReturnSuccess == err) {
    err = IOCreatePlugInInterfaceForService(hidDevice,
                                            kIOHIDDeviceUserClientTypeID,
                                            kIOCFPlugInInterfaceID,
                                            &plugInInterface, &score);
  }
  if (kIOReturnSuccess == err) {
    err = (*plugInInterface)->QueryInterface(plugInInterface,
                                             CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID),
                                             (LPVOID)hdi);
    (*plugInInterface)->Release(plugInInterface);
  }

  return err == 0;
}

static
bool _WBAppleRemoteTigerGetCookies(IOHIDDeviceInterface122 **hdi, IOHIDElementCookie cookies[kWBAppleRemoteButtonCount]) {
  CFArrayRef elements;

  if ((*hdi)->copyMatchingElements(hdi, NULL, &elements) != kIOReturnSuccess)
    return false;

  for (CFIndex i = 0; i < CFArrayGetCount(elements); i++) {
    long number = 0;
    CFDictionaryRef element = CFArrayGetValueAtIndex(elements, i);
    CFTypeRef object = (CFDictionaryGetValue(element, CFSTR(kIOHIDElementCookieKey)));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
      continue;
    if(!CFNumberGetValue((CFNumberRef) object, kCFNumberLongType, &number))
      continue;
    IOHIDElementCookie cookie = (IOHIDElementCookie)number;

    object = CFDictionaryGetValue(element, CFSTR(kIOHIDElementUsageKey));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
      continue;
    if (!CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &number))
      continue;
    long usage = number;

    object = CFDictionaryGetValue(element,CFSTR(kIOHIDElementUsagePageKey));
    if (object == 0 || CFGetTypeID(object) != CFNumberGetTypeID())
      continue;
    if (!CFNumberGetValue((CFNumberRef)object, kCFNumberLongType, &number))
      continue;
    long usagePage = number;

    if (usagePage == kHIDPage_GenericDesktop) {
      switch (usage) {
        case kHIDUsage_GD_SystemAppMenu:
          cookies[kWBAppleRemoteButtonMenu] = cookie;
          break;
        case kHIDUsage_GD_SystemMenu:
          cookies[kWBAppleRemoteButtonSelect] = cookie;
          break;
        case kHIDUsage_GD_SystemMenuRight:
          cookies[kWBAppleRemoteButtonRight] = cookie;
          break;
        case kHIDUsage_GD_SystemMenuLeft:
          cookies[kWBAppleRemoteButtonLeft] = cookie;
          break;
        case kHIDUsage_GD_SystemMenuUp:
          cookies[kWBAppleRemoteButtonUp] = cookie;
          break;
        case kHIDUsage_GD_SystemMenuDown:
          cookies[kWBAppleRemoteButtonDown] = cookie;
          break;
      }
    } else if (usagePage == kHIDPage_Consumer) {
      switch (usage) {
        case kHIDUsage_Csmr_Rewind:
          cookies[kWBAppleRemoteButtonRewind] = cookie;
          break;
        case kHIDUsage_Csmr_FastForward:
          cookies[kWBAppleRemoteButtonFastForward] = cookie;
          break;
      }
    }
  }
  return true;
}


- (id)initWithService:(io_service_t)service options:(IOOptionBits)options {
  if (self = [super initWithService:service options:(IOOptionBits)options]) {

    if (!_WBAppleRemoteTigerCreateInterface(service, &wb_plugin)) {
      [self release];
      return nil;
    }

    if (!_WBAppleRemoteTigerGetCookies((IOHIDDeviceInterface122 **)wb_plugin, wb_cookies)) {
      [self release];
      return nil;
    }

    if (kIOReturnSuccess != (*wb_plugin)->open(wb_plugin, options)) {
      [self release];
      return nil;
    }

    /* prepare queue */
    HRESULT err = S_OK;
    wb_queue = (*wb_plugin)->allocQueue(wb_plugin);
    if (wb_queue) {
      err = (*wb_queue)->create(wb_queue, 0, 8);
      if (S_OK == err) {
        for (CFIndex idx = 0; S_OK == err && idx < kWBAppleRemoteButtonCount; idx++)
          err = (*wb_queue)->addElement(wb_queue, wb_cookies[idx], 0);
      }
      if (S_OK == err)
        err = (*wb_queue)->setEventCallout(wb_queue, _WBAppleRemoteTigerCallback, NULL, self);
    }
    if (S_OK != err) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [self removeFromRunLoop:[NSRunLoop currentRunLoop]];
  if (wb_queue) {
    (*wb_queue)->dispose(wb_queue);
    (*wb_queue)->Release(wb_queue);
    wb_queue = NULL;
  }
  if (wb_plugin) {
    (*wb_plugin)->close(wb_plugin);
    (*wb_plugin)->Release(wb_plugin);
    wb_plugin = NULL;
  }
  spx_dealloc();
}

#pragma mark -
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_src) return;
  HRESULT err = (*wb_queue)->createAsyncEventSource(wb_queue, &wb_src);

  if (S_OK == err) {
    CFRunLoopAddSource([aRunLoop getCFRunLoop], wb_src, kCFRunLoopCommonModes);
    err = (*wb_queue)->start(wb_queue);
  }

  if (S_OK != err) {
    spx_log_warning("Error while starting remote event listener.");
    [self removeFromRunLoop:aRunLoop];
  }
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop {
  if (wb_queue) (*wb_queue)->stop(wb_queue);
  if (wb_src) {
    CFRunLoopSourceInvalidate(wb_src);
    CFRelease(wb_src);
    wb_src = NULL;
  }
}

@end

