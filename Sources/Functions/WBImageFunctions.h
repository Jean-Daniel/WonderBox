/*
 *  WBImageFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_IMAGE_FUNCTIONS_H)
#define __WB_IMAGE_FUNCTIONS_H 1

#import <WonderBox/WBBase.h>

WB_EXPORT
void WBImageSetRepresentationsSize(NSImage *image, NSSize size);

#pragma mark -
WB_EXPORT
NSBitmapImageRep *WBImageResizeImage(NSImage *anImage, NSSize size);

#endif /* __WBIMAGE_FUNCTIONS_H */
