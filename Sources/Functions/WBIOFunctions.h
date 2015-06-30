/*
 *  WBIOFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_IO_FUNCTIONS_H)
#define __WB_IO_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

#include <CoreFoundation/CoreFoundation.h>

__BEGIN_DECLS

/* High level Functions */
WB_EXPORT
CFIndex WBCFStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex length);

WB_EXPORT
CFIndex WBCFStreamWrite(CFWriteStreamRef stream, UInt8 *buffer, CFIndex length);

__END_DECLS

#endif /* __WB_IO_FUNCTIONS_H */
