/*
 *  WBMediaFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBMEDIA_FUNCTIONS_H)
#define __WBMEDIA_FUNCTIONS_H 1

#import <QTKit/QTKit.h>

/* Core Video */
WB_EXPORT
QTTime WBCVBufferGetMovieTime(CVBufferRef buffer);


/* Pretty print helper */
WB_EXPORT
NSString *WBMediaStringForPixelFormat(OSType format);

WB_EXPORT
CFStringRef WBMediaCopyStringForPixelFormat(OSType format);


/* Debugging purpose */
WB_EXPORT
void WBMediaPrintAtomContainer(QTAtomContainer atoms);

WB_EXPORT
void WBMediaPrintAtoms(QTAtomContainer atoms, QTAtom parentAtom, CFIndex level);


#endif /* __WBMEDIA_FUNCTIONS_H */
