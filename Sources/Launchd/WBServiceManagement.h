/*
 *  WBServiceManagement.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <launch.h>
#include <CoreFoundation/CoreFoundation.h>

extern Boolean WBServiceRegisterJob(CFDictionaryRef job, CFErrorRef *outError);
extern Boolean WBServiceUnregisterJob(CFStringRef name, CFErrorRef *outError);

extern Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
extern Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);

extern CFTypeRef WBServiceCheckIn(CFErrorRef *outError);
extern launch_data_t WBServiceCheckIn2(CFErrorRef *outError);

//extern void WBServiceCleanupObject(CFTypeRef aService);
