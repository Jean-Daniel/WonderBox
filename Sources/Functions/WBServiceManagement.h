//
//  WBServiceManagement.h
//  bootstrap
//
//  Created by Jean-Daniel Dupas on 17/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

WB_EXPORT Boolean WBServiceSubmitJob(CFDictionaryRef job, CFErrorRef *outError);
WB_EXPORT Boolean WBServiceRemoveJob(CFStringRef name, CFErrorRef *outError);

WB_EXPORT Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError);
WB_EXPORT Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError);
