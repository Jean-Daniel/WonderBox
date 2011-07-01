/*
 *  WBServiceManagement.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBBase.h)

#include <launch.h>
#include <CoreFoundation/CoreFoundation.h>

WB_EXPORT Boolean WBServiceRegisterJob(CFDictionaryRef job, CFErrorRef *outError);
WB_EXPORT Boolean WBServiceUnregisterJob(CFStringRef name, CFErrorRef *outError);

WB_EXPORT Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
WB_EXPORT Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);

WB_EXPORT CFDictionaryRef WBServiceCopyJob(CFStringRef name, CFErrorRef *outError);

WB_EXPORT CFTypeRef WBServiceCheckIn(CFErrorRef *outError) CF_RETURNS_RETAINED;
WB_EXPORT launch_data_t WBServiceCheckIn2(CFErrorRef *outError);

//WB_EXPORT void WBServiceCleanupObject(CFTypeRef aService);
