/*
 *  WBIOKitFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBIOKitFunctions.h>

#include <pthread.h>

#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>

const uint8_t kWBHIDEjectKey = NX_SUBTYPE_EJECT_KEY;
const uint8_t kWBHIDPowerKey = NX_SUBTYPE_POWER_KEY;

const uint8_t kWBHIDSleepEvent = NX_SUBTYPE_SLEEP_EVENT;
const uint8_t kWBHIDRestartEvent = NX_SUBTYPE_RESTART_EVENT;
const uint8_t kWBHIDShutdownEvent = NX_SUBTYPE_SHUTDOWN_EVENT;

static pthread_mutex_t sInitMutex;

__attribute__((constructor)) static void __Initialize(void) {
  pthread_mutex_init(&sInitMutex, NULL);
}

io_connect_t WBHIDGetEventDriver(void) {
  static mach_port_t sEventDrvrRef = 0;
  if (sEventDrvrRef) return sEventDrvrRef;

  pthread_mutex_lock(&sInitMutex);
  if (!sEventDrvrRef) {
    kern_return_t kr;
    mach_port_t service, iter;

    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOHIDSystemClass), &iter);
    assert(KERN_SUCCESS == kr);

    service = IOIteratorNext(iter);
    assert(service);

    kr = IOServiceOpen(service, mach_task_self(), kIOHIDParamConnectType, &sEventDrvrRef);
    assert(KERN_SUCCESS == kr);

    IOObjectRelease(service);
    IOObjectRelease(iter);
  }
  pthread_mutex_unlock(&sInitMutex);

  return sEventDrvrRef;
}


kern_return_t WBHIDPostAuxKey(const UInt8 auxKeyCode ) {
  kern_return_t kr;
  NXEventData event = {};
  IOGPoint loc = { 0, 0 };

  event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
  event.compound.misc.S[0] = auxKeyCode;
  event.compound.misc.C[2] = NX_KEYDOWN;

  IOOptionBits options = kIOHIDSetGlobalEventFlags;
  kr = IOHIDPostEvent(WBHIDGetEventDriver(), NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, options);
  assert( KERN_SUCCESS == kr );

  event.compound.misc.C[2] = NX_KEYUP;
  kr = IOHIDPostEvent(WBHIDGetEventDriver(), NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, options);

  return kr;
}

kern_return_t WBHIDPostSystemDefinedEvent(const UInt8 inSysKeyCode) {
  kern_return_t kr;
  NXEventData event = {};
  IOGPoint loc = { 0, 0 };

  event.compound.subType = inSysKeyCode;

  kr = IOHIDPostEvent(WBHIDGetEventDriver(), NX_SYSDEFINED, loc, &event, kNXEventDataVersion, 0, kIOHIDSetGlobalEventFlags);
  assert(KERN_SUCCESS == kr);

  return kr;
}

CGError WBIODisplayGetFloatParameter(CFStringRef key, float *value) {
  return IODisplayGetFloatParameter(CGDisplayIOServicePort(CGMainDisplayID()), kNilOptions, key, value);
}

CGError WBIODisplaySetFloatParameter(CFStringRef key, float value) {
  CGError err;
  CGDisplayCount max;
  io_service_t service;
  CGDirectDisplayID	displayIDs[8];

  err = CGGetOnlineDisplayList(8, displayIDs, &max);
  spx_require(kCGErrorSuccess == err, bail);

  if(max > 8)
    max = 8;

  for(CGDisplayCount idx = 0; idx < max; idx++ ) {
    service = CGDisplayIOServicePort(displayIDs[idx]);
    err = IODisplaySetFloatParameter(service, kNilOptions, key, value);
    if(kIOReturnSuccess != err)
      continue;
  }

bail:
  return err;
}
