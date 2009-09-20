//
//  WBService.h
//  dæmon
//
//  Created by Jean-Daniel Dupas on 18/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#include <mach/mach.h>
#include <CoreFoundation/CoreFoundation.h>

typedef boolean_t (*WBServiceDispatch)(mach_msg_header_t *req, mach_msg_header_t *res);

WB_PRIVATE bool WBServiceRun(const char *name, WBServiceDispatch dispatch, mach_msg_size_t maxSize, CFTimeInterval idle, CFErrorRef *outError);
WB_PRIVATE void WBServiceStop(void);
