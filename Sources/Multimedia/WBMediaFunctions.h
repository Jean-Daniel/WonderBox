/*
 *  WBMediaFunctions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
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
