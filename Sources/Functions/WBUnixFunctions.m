/*
 *  WBUnixFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBUnixFunctions.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/param.h>

#include <netdb.h>
#include <sys/un.h>
#include <sys/socket.h>

int WBIOSetNonBlocking(int fd) {
  // According to the man page, F_GETFL can't error!
  int flags = fcntl(fd, F_GETFL, NULL);

  if (-1 == fcntl(fd, F_SETFL, flags | O_NONBLOCK))
    return errno;
  return 0;
}

size_t WBIORead(int fd, uint8_t *buffer, size_t length, size_t *bytesRead) {
  check(fd > 0);
  check(length > 0);
  check(buffer != NULL);

  int err = 0;
  size_t done = 0;
  size_t bytesLeft;

  uint8_t *cursor = buffer;
  bytesLeft = length;
  while ( (0 == err) && (bytesLeft != 0) ) {
    ssize_t bytesThisTime = read(fd, cursor, bytesLeft);
    if (bytesThisTime > 0) {
      done      += bytesThisTime;
      cursor    += bytesThisTime;
      bytesLeft -= bytesThisTime;
    } else {
      err = errno;
    }
  }
  if (bytesRead)
    *bytesRead = length - bytesLeft;
  return done;
}

size_t WBIOWrite(int fd, const uint8_t *buffer, size_t length, size_t *bytesWritten) {
  check(fd > 0);
  check(length > 0);
  check(buffer != NULL);

  int err = 0;
  size_t done = 0;
  size_t bytesLeft;
  const uint8_t *cursor = buffer;
  bytesLeft = length;
  while ( (0 == err) && (bytesLeft != 0) ) {
    ssize_t bytesThisTime = write(fd, cursor, bytesLeft);
    if (bytesThisTime > 0) {
      done      += bytesThisTime;
      cursor    += bytesThisTime;
      bytesLeft -= bytesThisTime;
    } else {
      err = errno;
    }
  }
  if (bytesWritten)
    *bytesWritten = length - bytesLeft;
  return done;
}

// MARK: File Descriptor Passing
typedef union {
  struct cmsghdr cmsghdr;
  u_char msg_control[CMSG_SPACE(sizeof(int))];
} cmsghdr_msg_control_t;

ssize_t WBIOSendFileDescriptor(int sockfd, int fd) {
  ssize_t                ret;
  struct msghdr          msg;
  struct iovec           iovec[1];
  struct cmsghdr        *cmsghdrp;
  cmsghdr_msg_control_t  cmsghdr_msg_control;

  iovec[0].iov_base = (char *)"";
  iovec[0].iov_len = 1;

  msg.msg_name = (caddr_t)0; // address (optional)
  msg.msg_namelen = 0;       // size of address
  msg.msg_iov = iovec;       // scatter/gather array
  msg.msg_iovlen = 1;        // members in msg.msg_iov
  msg.msg_control = cmsghdr_msg_control.msg_control; // ancillary data
  // ancillary data buffer length
  msg.msg_controllen = sizeof(cmsghdr_msg_control.msg_control);
  msg.msg_flags = 0;          // flags on received message

  // CMSG_FIRSTHDR() returns a pointer to the first cmsghdr structure in
  // the ancillary data associated with the given msghdr structure
  cmsghdrp = CMSG_FIRSTHDR(&msg);

  cmsghdrp->cmsg_len = CMSG_LEN(sizeof(int)); // data byte count
  cmsghdrp->cmsg_level = SOL_SOCKET;          // originating protocol
  cmsghdrp->cmsg_type = SCM_RIGHTS;           // protocol-specified type

  // CMSG_DATA() returns a pointer to the data array associated with
  // the cmsghdr structure pointed to by cmsghdrp
  *((int *)CMSG_DATA(cmsghdrp)) = fd;

  if ((ret = sendmsg(sockfd, &msg, 0)) < 0) {
    spx_debug("sendmsg: %s", strerror(errno));
    return ret;
  }

  return 0;
}

ssize_t WBIOReceiveFileDescriptor(int sockfd, int *fd) {
  ssize_t                ret;
  u_char                 c;
  int                    errcond = 0;
  struct iovec           iovec[1];
  struct msghdr          msg;
  struct cmsghdr        *cmsghdrp;
  cmsghdr_msg_control_t  cmsghdr_msg_control;

  iovec[0].iov_base = &c;
  iovec[0].iov_len = 1;

  msg.msg_name = (caddr_t)0;
  msg.msg_namelen = 0;
  msg.msg_iov = iovec;
  msg.msg_iovlen = 1;
  msg.msg_control = cmsghdr_msg_control.msg_control;
  msg.msg_controllen = sizeof(cmsghdr_msg_control.msg_control);
  msg.msg_flags = 0;

  if ((ret = recvmsg(sockfd, &msg, 0)) <= 0) {
    spx_debug("recvmsg: %s", strerror(errno));
    return ret;
  }

  cmsghdrp = CMSG_FIRSTHDR(&msg);

  if (cmsghdrp == NULL) {
    *fd = -1;
    return ret;
  }

  if (cmsghdrp->cmsg_len != CMSG_LEN(sizeof(int)))
    errcond++;

  if (cmsghdrp->cmsg_level != SOL_SOCKET)
    errcond++;

  if (cmsghdrp->cmsg_type != SCM_RIGHTS)
    errcond++;

  if (errcond) {
    spx_debug("%d errors in received message\n", errcond);
    *fd = -1;
  } else
    *fd = *((int *)CMSG_DATA(cmsghdrp));

  return ret;
}

// MARK: Dump Descriptors

// Gets either the socket name or the peer name from the socket
// (depending on the peer parameter) and converts it to a human
// readable string.  The caller is responsible for freeing the
// memory.
static
char *SockAddrToString(int fd, Boolean peer) {
  int err;
  char * result;
  size_t resultLen;
  union {
    struct sockaddr addr;
    char pad[SOCK_MAXADDRLEN];
  } paddedAddr;

  socklen_t addrLen = sizeof(paddedAddr);
  assert(addrLen == SOCK_MAXADDRLEN);

  // Socket name, or peer name?

  if (peer) {
    err = getpeername(fd, &paddedAddr.addr, &addrLen);
  } else {
    err = getsockname(fd, &paddedAddr.addr, &addrLen);
  }

  // Convert the result to a string.

  if ( (err == -1) || (addrLen < offsetof(struct sockaddr, sa_data))) {
    result = strdup("?");
  } else {
    char hostStr[NI_MAXHOST];
    char servStr[NI_MAXSERV];

    assert(addrLen >= offsetof(struct sockaddr, sa_data));
    assert(addrLen == paddedAddr.addr.sa_len);

    err = getnameinfo(
                      &paddedAddr.addr,
                      addrLen,
                      hostStr,
                      sizeof(hostStr),
                      servStr,
                      sizeof(servStr),
                      NI_NUMERICHOST | NI_NUMERICSERV
                      );
    if (err == 0) {
      // Cool.  getnameinfo did all the heavy lifting, so we just return the results.

      resultLen = strlen(hostStr) + 1 + strlen(servStr) + 1;
      result = malloc(resultLen);
      if (result != NULL) {
        snprintf(result, resultLen, "%s %s", hostStr, servStr);
      }
    } else {
      // Drat.  getnameinfo isn't helping out with this address, so we have to do it
      // all by hand.

      switch (paddedAddr.addr.sa_family) {
        case AF_UNIX:
        {
          struct sockaddr_un * unAddr;

          assert(addrLen < SOCK_MAXADDRLEN);
          paddedAddr.pad[addrLen] = 0;
          unAddr = (struct sockaddr_un *) &paddedAddr.addr;
          result = strdup( unAddr->sun_path );
        }
          break;
        default:
          assert(false);
          result = strdup("unrecognised address");
          break;
      };
    }
  }

  return result;
}

void WBIODumpDescriptorTable(FILE *f) {
  static const char * kSockTypeToStr[] = {
    "unknown    ",
    "SOCK_STREAM",
    "SOCK_DGRAM ",
    "SOCK_RAW   ",
    "SOCK_RDM   ",
    "SOCK_SEQPACKET"            // not going to see this anyway, so don't need to pad everything else to this long length
  };
  if (!f) f = stderr;
  int descCount = getdtablesize();
  fprintf(f, "Descriptors:\n");
  for (int descIndex = 0; descIndex < descCount; descIndex++) {
    if ( fcntl(descIndex, F_GETFD, NULL) != -1 ) {
      // Descriptor is active, let's try to find out what it is.
      // See if we can get a file path from it.
      char pathBuf[MAXPATHLEN];
      int err = fcntl(descIndex, F_GETPATH, pathBuf);
      if (err != -1) {
        // If it's a file, print its path.
        fprintf(f, "  %2d file    '%s'\n", descIndex, pathBuf);
      } else {
        // See if it's a socket.
        int sockType;
        socklen_t sockTypeLen = sizeof(sockType);
        err = getsockopt(descIndex, SOL_SOCKET, SO_TYPE, &sockType, &sockTypeLen);
        if (err != -1) {
          char *localStr = NULL;
          char *peerStr = NULL;
          const char *sockTypeStr;

          // If it's a socket, print the local and remote address.
          localStr = SockAddrToString(descIndex, false);
          peerStr  = SockAddrToString(descIndex, true);

          if ( (sockType < 0) || (sockType > (int)(sizeof(kSockTypeToStr) / sizeof(kSockTypeToStr[0]))) ) {
            sockTypeStr = kSockTypeToStr[0];
          } else {
            sockTypeStr = kSockTypeToStr[sockType];
          }
          if (sockTypeStr == kSockTypeToStr[0]) {
            fprintf(f, "  %2d socket  %s (%d) %s -> %s\n", descIndex, sockTypeStr, sockType, localStr, peerStr);
          } else {
            fprintf(f, "  %2d socket  %s %s -> %s\n", descIndex, sockTypeStr, localStr, peerStr);
          }

          free(localStr);
          free(peerStr);
        } else {

          // No idea.

          fprintf(f, "  %2d unknown\n", descIndex);
        }
      }
    }
  }
}

// MARK: -
// MARK: Signal Functions
// MARK: -
int WBSignalIgnoreSIGPIPE(void) {
  struct sigaction signalState;
  if (sigaction(SIGPIPE, NULL, &signalState) == -1)
    return errno;

  signalState.sa_handler = SIG_IGN;
  if (sigaction(SIGPIPE, &signalState, NULL) == -1)
    return errno;

  return 0;
}

static struct {
  int sink; /* fd */
  CFSocketRef socket;
  WBSignalHandlerCallBack handler;
} gSignalHandler;

// A signal handler that catches the signal and forwards it
// to the runloop via gSignalSinkFD.  This code is careful to
// only use signal safe routines (except for the asserts,
// of course, but they're compiled out on production builds).
static
void _WBSignalToSocketHandler(int sig, siginfo_t *sigInfo, void *uap) {
#pragma unused(uap)
  ssize_t junk;

  assert(gSignalHandler.sink != 0);
  assert(sig == sigInfo->si_signo);

  junk = write(gSignalHandler.sink, sigInfo, sizeof(*sigInfo));

  // There's not much I can do if this fails.  Missing a signal
  // isn't such a big deal, but writing only a partial siginfo_t
  // to the socket would be bad.
  assert(junk == sizeof(*sigInfo));
}

// Call in the context of the runloop when data arrives on the
// UNIX domain socket shared with the signal handler.  This
// reads the information about the signal and passes to the client's
// callback.
static
void _WBSignalCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type,
                               CFDataRef address, const void *data, void *info) {
  int err;
  siginfo_t	sigInfo;

  assert(gSignalHandler.socket != NULL);
  assert(gSignalHandler.handler != NULL);

  // Problem with our private socket ?
  if (kCFSocketReadCallBack != type) return;

  err = WBIORead(CFSocketGetNative(gSignalHandler.socket), (uint8_t *)&sigInfo, sizeof(sigInfo), NULL);
  if (0 == err)
    gSignalHandler.handler(&sigInfo, info);
  assert(err == 0);
}

int WBSignalInstallHandler(CFRunLoopRef runLoop,
                           CFStringRef runLoopMode,
                           WBSignalHandlerCallBack callback, WBSignalContext *ctxt, int sig, ...) {
  assert(sig != 0);
  assert(runLoop != NULL);
  assert(callback != NULL);
  assert(runLoopMode != NULL);

  /* Does not support 2 calls */
  if (gSignalHandler.handler) return EPERM;

  // Create a UNIX domain socket pair and assign them to the
  // sink (where the signal handler writes the information) and
  // source variables (where the runloop callback reads it).
  int sockets[2];
  int err = 0;
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockets) < 0)
    err = errno;
  // gSignalSinkFD  = sockets[0];

  gSignalHandler.sink = sockets[0];
  // We set the signal sink socket to non-blocking because, if the
  // socket fills up, there's a possibility we might deadlock with
  // ourselves (the signal handler blocks trying to write data to
  // a full socket, but the runloop thread can't read data from the
  // socket because it has been interrupted by the signal handler).
  if (0 == err)
    err = WBIOSetNonBlocking(gSignalHandler.sink);

  // Wrap the destination socket in a CFSocket, and create a
  // runloop source for it.  The associated callback (SignalCFSocketCallback)
  // receives information about the signal from the signal handler
  // and passes it along to the client's callback, but it's now in the context
  // of the runloop.
  if (0 == err) {
    CFSocketContext sctxt;
    if (ctxt) {
      sctxt.version = ctxt->version;
      sctxt.info = ctxt->info;
      sctxt.retain = ctxt->retain;
      sctxt.release = ctxt->release;
      sctxt.copyDescription = ctxt->copyDescription;
    }
    gSignalHandler.socket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1],
                                                     kCFSocketCloseOnInvalidate | kCFSocketReadCallBack,
                                                     _WBSignalCFSocketCallBack,  ctxt ? &sctxt : NULL);
    if (!gSignalHandler.socket)
      err = EINVAL;
  }

  int junk;
  if (0 == err) {
    gSignalHandler.handler = callback;

    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(kCFAllocatorDefault, gSignalHandler.socket, 0);
    if (!rls)
      err = EINVAL;

    if (0 == err) {
      CFRunLoopAddSource(runLoop, rls, runLoopMode);

      // For each signal in the set, register our signal handler
      // (SignalToSocketHandler).  Specificy SA_SIGINFO so that
      // the handler gets lots of yummy signal information.
      va_list args;
      va_start(args, sig);
      while (sig) {
        if (sig < NSIG) {
          struct sigaction newSignalAction = {
            .sa_sigaction = _WBSignalToSocketHandler,
            .sa_flags = SA_SIGINFO
          };
          sigemptyset(&newSignalAction.sa_mask);
          junk = sigaction(sig, &newSignalAction, NULL);
          assert(junk == 0);
          // Error recovery here would be hard.  We'd have to undo
          // any previous signal handlers that were installed
          // (requiring us to get the previous value and remembering
          // it) and then it would also require us to remove the
          // run loop source.  All-in-all, not worth the effort
          // given the very small chance of an error from sigaction.
        }
        sig = va_arg(args, int);
      }
      va_end(args);
    }

    // We don't need the runloop source from here on, so release our
    // reference to it.  It still exists because the runloop knows about it.
    SPXCFRelease(rls);
  }

  // Clean up.
  if (err != 0) {
    gSignalHandler.handler = NULL;
    if (gSignalHandler.socket) {
      CFSocketInvalidate(gSignalHandler.socket);
      CFRelease(gSignalHandler.socket);
      gSignalHandler.socket = NULL;
    } else if (sockets[1]) {
      junk = close(sockets[1]);
      assert(junk == 0);
    }
    if (gSignalHandler.sink) {
      junk = close(gSignalHandler.sink);
      gSignalHandler.sink = 0;
      assert(junk == 0);
    }
  }

  return err;
}

