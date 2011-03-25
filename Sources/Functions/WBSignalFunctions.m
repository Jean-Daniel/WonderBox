/*
 *  WBSignalFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBSignalFunctions.h)

int WBSignalIgnoreSIGPIPE(void) {
  struct sigaction signalState;
  int err = sigaction(SIGPIPE, NULL, &signalState);
  err = WBErrno(err);
  if (err == 0) {
    signalState.sa_handler = SIG_IGN;

    err = sigaction(SIGPIPE, &signalState, NULL);
    err = WBErrno(err);
  }

  return err;
}
