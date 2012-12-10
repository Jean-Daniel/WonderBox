/*
 *  WBService.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBBase.h>

#include <mach/mach.h>
#include <CoreFoundation/CoreFoundation.h>

typedef boolean_t (*WBServiceDispatch)(mach_msg_header_t *req, mach_msg_header_t *res);

WB_PRIVATE
bool WBServiceRun(const char *name, WBServiceDispatch dispatch,
                  mach_msg_size_t msgMaxSize, CFTimeInterval idle, CFErrorRef *outError);
WB_PRIVATE void WBServiceStop(void);

WB_PRIVATE kern_return_t WBServiceSetTimeout(CFTimeInterval idle);
WB_PRIVATE kern_return_t WBServiceSetTimeoutCallBack(void (*callback)(void *), void *ctxt);
