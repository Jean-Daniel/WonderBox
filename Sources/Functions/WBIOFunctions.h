/*
 *  WBIOFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBIOFUNCTIONS_H)
#define __WBIOFUNCTIONS_H 1

/* Low level functions */
WB_EXPORT
size_t WBIOUtilsRead(int fd, UInt8 *buffer, size_t length);

WB_EXPORT
size_t WBIOUtilsWrite(int fd, UInt8 *buffer, size_t length);

WB_EXPORT
ssize_t WBIOUtilsSendFileDescriptor(int sockfd, int fd);
WB_EXPORT
ssize_t WBIOUtilsReceiveFileDescriptor(int sockfd, int *fd);

/* High level Functions */
WB_EXPORT
CFIndex WBCFStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex length);

WB_EXPORT
CFIndex WBCFStreamWrite(CFWriteStreamRef stream, UInt8 *buffer, CFIndex length);


#endif /* __WBIOFUNCTIONS_H */
