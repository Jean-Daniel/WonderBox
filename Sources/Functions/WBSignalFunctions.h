/*
 *  WBSignalFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_SIGNAL_FUNCTIONS_H)
#define __WB_SIGNAL_FUNCTIONS_H 1

#include WBHEADER(WBBase.h)

/*!
 @function
 @abstract Sets the handler for SIGPIPE to SIG_IGN.
 If you don't call this, writing to a broken pipe will cause
 SIGPIPE (rather than having "write" return EPIPE), which
 is hardly ever what you want.
 */
WB_EXPORT
int WBSignalIgnoreSIGPIPE(void);

#endif /* __WB_SIGNAL_FUNCTIONS_H */
