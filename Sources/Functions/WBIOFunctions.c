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

CFIndex WBCFStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex length) {
  check(length > 0);
  check(stream != NULL);
  check(buffer != NULL);

  UInt8 *cursor;
  bool ok = true;
  CFIndex done = 0;
  CFIndex bytesLeft;
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
  CFIndex bytesLeft;
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

