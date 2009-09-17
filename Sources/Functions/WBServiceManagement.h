//
//  WBServiceManagement.h
//  bootstrap
//
//  Created by Jean-Daniel Dupas on 17/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

extern Boolean WBServiceSubmitJob(CFDictionaryRef job, CFErrorRef *outError);
extern Boolean WBServiceRemoveJob(CFStringRef name, CFErrorRef *outError);

extern Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
extern Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);

extern CFTypeRef WBServiceCheckIn(CFStringRef name, CFErrorRef *outError);
