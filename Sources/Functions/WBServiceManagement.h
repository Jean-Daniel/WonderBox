//
//  WBServiceManagement.h
//  bootstrap
//
//  Created by Jean-Daniel Dupas on 17/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#include <launch.h>

extern Boolean WBServiceSubmitJob(CFDictionaryRef job, CFErrorRef *outError);
extern Boolean WBServiceRemoveJob(CFStringRef name, CFErrorRef *outError);

extern Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
extern Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);

extern CFTypeRef WBServiceCheckIn(CFStringRef name, CFErrorRef *outError);

/*!
 @function
 @abstract Cleanup a Service retrieve using Check-In (close file descriptors, destroy Mach Ports, etc.)
 */
extern void WBServiceCleanupObject(CFTypeRef aService);
