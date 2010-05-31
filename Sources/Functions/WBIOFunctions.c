/*
 *  WBIOFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBIOFunctions.h)

#include <fcntl.h>
#include <unistd.h>
#include <sys/un.h>
#include <sys/socket.h>

/* Low level functions */
size_t WBIOUtilsRead(int fd, UInt8 *buffer, size_t length) {
  check(fd > 0);
	check(length > 0);
	check(buffer != NULL);
	
	UInt8 *cursor;
	bool ok = true;
	size_t done = 0;
	size_t	bytesLeft;
	size_t bytesThisTime;
	
	cursor = buffer;
	bytesLeft = length;
	while ( ok && (bytesLeft != 0) ) {
		bytesThisTime = read(fd, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			done      += bytesThisTime;
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else {
			ok = false;
		}
	}
	
	return done;
}

size_t WBIOUtilsWrite(int fd, UInt8 *buffer, size_t length) {
  check(fd > 0);
  check(length > 0);
	check(buffer != NULL);
	
	UInt8 *cursor;
	bool ok = true;
	size_t done = 0;
	size_t bytesLeft;
	size_t bytesThisTime;
	
	cursor = buffer;
	bytesLeft = length;
	while ( ok && (bytesLeft != 0) ) {
		bytesThisTime = write(fd, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			done      += bytesThisTime;
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else {
			ok = false;
		}
	}
	
	return done;
}

CFIndex WBCFStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex length) {
	check(length > 0);
	check(stream != NULL);
	check(buffer != NULL);
	
	UInt8 *cursor;
	bool ok = true;
	CFIndex done = 0;
	CFIndex	bytesLeft;
	CFIndex bytesThisTime;
	
	cursor = buffer;
	bytesLeft = length;
	while ( ok && (bytesLeft != 0) ) {
		bytesThisTime = CFReadStreamRead(stream, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			done      += bytesThisTime;
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else {
			ok = false;
		}
	}
	
	return done;
}

CFIndex WBCFStreamWrite(CFWriteStreamRef stream, UInt8 *buffer, CFIndex length) {
	check(length > 0);
	check(stream != NULL);
	check(buffer != NULL);
	
	UInt8 *cursor;
	bool ok = true;
	CFIndex done = 0;
	CFIndex	bytesLeft;
	CFIndex bytesThisTime;
	
	cursor = buffer;
	bytesLeft = length;
	while ( ok && (bytesLeft != 0) ) {
		bytesThisTime = CFWriteStreamWrite(stream, cursor, bytesLeft);
		if (bytesThisTime > 0) {
			done      += bytesThisTime;
			cursor    += bytesThisTime;
			bytesLeft -= bytesThisTime;
		} else {
			ok = false;
		}
	}
	
	return done;
}

#pragma mark File Descriptoe Passing

typedef union {
  struct cmsghdr cmsghdr;
  u_char msg_control[CMSG_SPACE(sizeof(int))];
} cmsghdr_msg_control_t;

ssize_t WBIOUtilsSendFileDescriptor(int sockfd, int fd) {
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
    DCLog("sendmsg: %s", strerror(errno));
    return ret;
  }

  return 0;
}

ssize_t WBIOUtilsReceiveFileDescriptor(int sockfd, int *fd) {
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
    DCLog("recvmsg: %s", strerror(errno));
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
    DCLog("%d errors in received message\n", errcond);
    *fd = -1;
  } else
    *fd = *((int *)CMSG_DATA(cmsghdrp));

  return ret;
}

