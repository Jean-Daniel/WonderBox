/*
 *  WBUnixFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_UNIX_FUNCTIONS_H)
#define __WB_UNIX_FUNCTIONS_H 1

#include WBHEADER(WBBase.h)

// MARK: File Descriptor Functions
WB_EXPORT
int WBIOSetNonBlocking(int fd);

WB_EXPORT
size_t WBIORead(int fd, uint8_t *buffer, size_t length, size_t *bytesRead);

WB_EXPORT
size_t WBIOWrite(int fd, const uint8_t *buffer, size_t length, size_t *bytesWritten);

WB_EXPORT
ssize_t WBIOSendFileDescriptor(int sockfd, int fd);
WB_EXPORT
ssize_t WBIOReceiveFileDescriptor(int sockfd, int *fd);

/* Debug function */
WB_EXPORT
void WBIODumpDescriptorTable(FILE *f);

// MARK: Signal Functions
/*!
 @function
 @abstract Sets the handler for SIGPIPE to SIG_IGN.
 If you don't call this, writing to a broken pipe will cause
 SIGPIPE (rather than having "write" return EPIPE), which
 is hardly ever what you want.
 */
WB_EXPORT
int WBSignalIgnoreSIGPIPE(void);

// MARK: -
// MARK: Signal Handler
typedef struct {
  CFIndex version;
  void *info;
  const void *(*retain)(const void *info);
  void (*release)(const void *info);
  CFStringRef (*copyDescription)(const void *info);
} WBSignalContext;
typedef void (*WBSignalHandlerCallBack)(const siginfo_t *sigInfo, void *refCon);

/*!
 @function
 @abstract A method for routing signals to a runloop-based program.
 @param runLoop You typically pass CFRunLoopGetCurrent
 @param runLoopMode You typically pass kCFRunLoopCommonsMode
 @param callback the routine you want called.
 @param ctxt used to passe info to the handler.
 @param signal signal you want to catch. Must be terminated by 0.
 @discussion You can only call this routine once for any given application;
 you must register all of the signals you're interested in at that
 time. There is no way to deregister.
 */
WB_EXPORT
int WBSignalInstallHandler(CFRunLoopRef runLoop,
                           CFStringRef runLoopMode,
                           WBSignalHandlerCallBack callback, WBSignalContext *ctxt, int signal, ...) WB_REQUIRES_NIL_TERMINATION;


#endif /* __WB_UNIX_FUNCTIONS_H */
