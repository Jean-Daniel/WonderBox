/*
 *  WBMediaFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_MEDIA_FUNCTIONS_H)
#define __WB_MEDIA_FUNCTIONS_H 1

#import <WonderBox/WBBase.h>

#import <QTKit/QTKit.h>

/* Core Video */
WB_EXPORT
QTTime WBCVBufferGetMovieTime(CVBufferRef buffer);

/* Pretty print helper */
WB_EXPORT
NSString *WBMediaStringForPixelFormat(OSType format);

WB_EXPORT
CFStringRef WBMediaCopyStringForPixelFormat(OSType format);

WB_EXPORT
void WBQTMovieGetStaticFrameRate(QTMovie *aMovie, double *outStaticFrameRate);

/* Debugging purpose */
#if !defined(__LP64__) || !__LP64__
WB_EXPORT
void WBMediaPrintAtomContainer(QTAtomContainer atoms);

WB_EXPORT
void WBMediaPrintAtoms(QTAtomContainer atoms, QTAtom parentAtom, CFIndex level);
#endif

#endif /* __WB_MEDIA_FUNCTIONS_H */
