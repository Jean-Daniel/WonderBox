/*
 *  WBIcnsCodec.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_ICNS_CODEC_H)
#define __WB_ICNS_CODEC_H 1

#include WBHEADER(WBBase.h)

WB_PRIVATE
Handle WBIconFamilyGet32BitDataForBitmap(NSBitmapImageRep *bitmap);
WB_PRIVATE
Handle WBIconFamilyGet8BitDataForBitmap(NSBitmapImageRep *bitmap);
WB_PRIVATE
Handle WBIconFamilyGet4BitDataForBitmap(NSBitmapImageRep *bitmap);
WB_PRIVATE
Handle WBIconFamilyGet8BitMaskForBitmap(NSBitmapImageRep *bitmap);
WB_PRIVATE
Handle WBIconFamilyGet1BitDataAndMaskForBitmap(NSBitmapImageRep *bitmap);

#pragma mark -
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor32BitData(NSData *aData, NSSize size, unsigned char *planes[]);
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor8BitData(NSData *data, NSSize size, unsigned char *planes[]);
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor4BitData(NSData *data, NSSize size, unsigned char *planes[]);
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor1BitData(NSData *data, NSSize size, unsigned char *planes[]);
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor8BitMask(NSData *data, NSSize size, unsigned char *planes[]);
WB_PRIVATE
NSUInteger WBIconFamilyBitmapDataFor1BitMask(NSData *data, NSSize size, unsigned char *planes[]);

#endif /* __WB_ICNS_CODEC_H */
