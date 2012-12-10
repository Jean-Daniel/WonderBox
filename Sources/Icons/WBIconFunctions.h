/*
 *  WBIconFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

/*!
@header WBIconFunctions
 @abstract Functions to manipulate Finder icons.
 */

#if !defined(__WB_ICON_FUNCTIONS_H)
#define __WB_ICON_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

#pragma mark Miscellaneous Functions
/*!
@function
 @abstract
 @param fileRef A valid FSRef.
 @param hasCustomIcon On return, contains a true if fileRef has cutom icon flag setted.
 @result Return A result code.
*/
OSStatus WBIconFileHasCustomIcon(const FSRef *fileRef, Boolean *hasCustomIcon);
/*!
@function
 @abstract
 @param fourByteCode System Icon identifier.
 @param icon On return, contains an icon family.
 @result Return A result code.
 */
OSStatus WBIconFamilyGetSystemIcon(OSType fourByteCode, IconFamilyHandle *icon);

#pragma mark -
#pragma mark Read Icon Family From 'icns' file
WB_EXPORT Boolean WBIconFamilyReadFromPath(CFStringRef path, IconFamilyHandle *iconFamily);
WB_EXPORT Boolean WBIconFamilyReadFromURL(CFURLRef url, IconFamilyHandle *iconFamily);
WB_EXPORT Boolean WBIconFamilyReadFromFSRef(const FSRef *ref, IconFamilyHandle *iconFamily);

#pragma mark Read Icon Family From Misc file
WB_EXPORT Boolean WBIconFamilyGetFromPath(CFStringRef path, IconFamilyHandle *iconFamily);
WB_EXPORT Boolean WBIconFamilyGetFromURL(CFURLRef url, IconFamilyHandle *iconFamily);
WB_EXPORT Boolean WBIconFamilyGetFromFSRef(const FSRef *ref, IconFamilyHandle *iconFamily);

#pragma mark -
#pragma mark Write Icon Family to 'icns' file
WB_EXPORT Boolean WBIconFamilyWriteToPath(IconFamilyHandle iconFamily, CFStringRef path, CFURLPathStyle pathStyle);
WB_EXPORT Boolean WBIconFamilyWriteToURL(IconFamilyHandle iconFamily, CFURLRef url);
WB_EXPORT OSStatus WBIconFamilyWriteToFSRef(IconFamilyHandle iconFamily, FSRef *ref);

#pragma mark Set File or Folder Custom Icon
WB_EXPORT Boolean WBIconFamilySetIconAtPath(IconFamilyHandle iconFamily, CFStringRef path, Boolean compatible);
WB_EXPORT Boolean WBIconFamilySetIconAtURL(IconFamilyHandle iconFamily, CFURLRef url, Boolean compatible);
WB_EXPORT Boolean WBIconFamilySetIcon(IconFamilyHandle iconFamily, const FSRef *ref, Boolean compatible);

WB_EXPORT Boolean WBIconFamilySetFileIcon(const FSRef *fsRef, IconFamilyHandle iconFamily, Boolean compatible);
WB_EXPORT Boolean WBIconFamilySetFolderIcon(const FSRef *folderRef, IconFamilyHandle iconFamily, Boolean compatible);

#pragma mark -
#pragma mark Remove File or Folder Custom Icon.
WB_EXPORT Boolean WBIconFamilyRemoveIconAtPath(CFStringRef path);
WB_EXPORT Boolean WBIconFamilyRemoveIconAtURL(CFURLRef url);
WB_EXPORT Boolean WBIconFamilyRemoveIcon(const FSRef *ref);

WB_EXPORT Boolean WBIconFamilyRemoveFileIcon(const FSRef *ref);
WB_EXPORT Boolean WBIconFamilyRemoveFolderIcon(const FSRef *ref);

#pragma mark -
#pragma mark Low Level Fields Access
WB_INLINE
OSType WBIconFamilyResourceGetType(IconFamilyResource *rsrc) { return OSSwapBigToHostInt32(rsrc->resourceType); }
WB_INLINE
void WBIconFamilyResourceSetType(IconFamilyResource *rsrc, OSType type) { rsrc->resourceType = OSSwapHostToBigInt32(type); }
WB_INLINE
SInt32 WBIconFamilyResourceGetSize(IconFamilyResource *rsrc) { return OSSwapBigToHostInt32(rsrc->resourceSize); }
WB_INLINE
void WBIconFamilyResourceSetSize(IconFamilyResource *rsrc, SInt32 size) { rsrc->resourceSize = OSSwapHostToBigInt32(size); }

WB_INLINE
OSType WBIconFamilyElementGetType(IconFamilyElement *elt) { return OSSwapBigToHostInt32(elt->elementType); }
WB_INLINE
void WBIconFamilyElementSetType(IconFamilyElement *elt, OSType type) { elt->elementType = OSSwapHostToBigInt32(type); }
WB_INLINE
SInt32 WBIconFamilyElementGetSize(IconFamilyElement *elt) { return OSSwapBigToHostInt32(elt->elementSize); }
WB_INLINE
void WBIconFamilyElementSetSize(IconFamilyElement *elt, SInt32 size) { elt->elementSize = OSSwapHostToBigInt32(size); }

WB_INLINE
IconFamilyResource *WBIconFamilyGetFamilyResource(IconFamilyHandle handle) {
		return (handle) ? *handle : nil;
}

WB_EXPORT
bool WBIsIconVariantType(OSType type);

#pragma mark IconFamily Iterator
struct _WBIconFamilyIterator {
  IconFamilyResource *_rsrc;
  IconFamilyElement *_elt;
  Size _position;
};
typedef struct _WBIconFamilyIterator WBIconFamilyIterator;

WB_INLINE
void WBIconFamilyIteratorInit(WBIconFamilyIterator *iterator, IconFamilyResource *rsrc) {
  iterator->_rsrc = rsrc;
  iterator->_elt = rsrc->elements;
  iterator->_position = sizeof(OSType) + sizeof(Size);
}

WB_INLINE
IconFamilyElement *WBIconFamilyIteratorNextElement(WBIconFamilyIterator *iterator) {
  IconFamilyElement *elt = NULL;
  if (iterator->_position < WBIconFamilyResourceGetSize(iterator->_rsrc)) {
    elt = iterator->_elt;
    Size size = WBIconFamilyElementGetSize(elt);
    if (size > 0) {
      iterator->_position += size;
      iterator->_elt = (IconFamilyElement *)((uint8_t *)elt + size);
    } else {
      elt = NULL;
      iterator->_position = WBIconFamilyResourceGetSize(iterator->_rsrc);
    }
  }
  return elt;
}

#endif /* __WBICON_FUNCTIONS_H */
