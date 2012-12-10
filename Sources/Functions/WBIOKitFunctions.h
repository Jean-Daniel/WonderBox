/*
 *  WBIOKitFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_IOKIT_FUNCTIONS_H)
#define __WB_IOKIT_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

#include <IOKit/IOTypes.h>
#include <ApplicationServices/ApplicationServices.h>

WB_EXPORT const int kWBHIDEjectKey;
WB_EXPORT const int kWBHIDPowerKey;

WB_EXPORT const int kWBHIDSleepEvent;
WB_EXPORT const int kWBHIDRestartEvent;
WB_EXPORT const int kWBHIDShutdownEvent;

enum {
  kWBKeySoundUp = 0,
  kWBKeySoundDown = 1,
  kWBKeyBrightnessUp = 2,
  kWBKeyBrightnessDown = 3,
  kWBKeyCapsLock = 4,
  kWBKeyHelp = 5,
  kWBKeyPower = 6,
  kWBKeyMute = 7,
  kWBKeyArrowUp = 8,
  kWBKeyArrowDown = 9,
  kWBKeyNumLock = 10,

  kWBKeyContrastUp = 11,
  kWBKeyContrastDown = 12,
  kWBKeyLaunchPanel = 13,
  kWBKeyEject = 14,
  kWBKeyVidMirror = 15,

  kWBKeyPlay = 16,
  kWBKeyNext = 17,
  kWBKeyPrevious = 18,
  kWBKeyFast = 19,
  kWBKeyRewind = 20,

  kWBKeyIlluminationUp = 21,
  kWBKeyIlluminationDown = 22,
  kWBKeyIlluminationToggle = 23,
};

WB_EXPORT
io_connect_t WBHIDGetEventDriver(void);

WB_EXPORT
kern_return_t WBHIDPostAuxKey(const UInt8 auxKeyCode);
WB_EXPORT
kern_return_t WBHIDPostSystemDefinedEvent(const UInt8 inSysKeyCode);

WB_EXPORT
CGError WBIODisplayGetFloatParameter(CFStringRef key, float *value);
WB_EXPORT
CGError WBIODisplaySetFloatParameter(CFStringRef key, float value);

#endif /* __WB_IOKIT_FUNCTIONS_H */
