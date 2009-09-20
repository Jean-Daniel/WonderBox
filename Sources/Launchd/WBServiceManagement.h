//
//  WBServiceManagement.h
//  bootstrap
//
//  Created by Jean-Daniel Dupas on 17/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#include <launch.h>
#include <CoreFoundation/CoreFoundation.h>

extern Boolean WBServiceRegisterJob(CFDictionaryRef job, CFErrorRef *outError);
extern Boolean WBServiceUnregisterJob(CFStringRef name, CFErrorRef *outError);

extern Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
extern Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);

extern CFTypeRef WBServiceCheckIn(CFErrorRef *outError);
extern launch_data_t WBServiceCheckIn2(CFErrorRef *outError);

//extern void WBServiceCleanupObject(CFTypeRef aService);
