/*
 *  WBLoginItems.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_LOGIN_ITEMS_H)
#define __WB_LOGIN_ITEMS_H 1

#include WBHEADER(WBBase.h)
#include <ApplicationServices/ApplicationServices.h>

// Keys for the dictionary return by WBLoginItemCopyItems.
WB_EXPORT
CFStringRef const kWBLoginItemURL;		// CFURL
WB_EXPORT
CFStringRef const kWBLoginItemHidden; 	// CFBoolean

WB_EXPORT
CFArrayRef WBLoginItemCopyItems(void);
// Returns an array of CFDictionaries, each one describing a
// login item.  Each dictionary has two elements,
// kLIAEURL and kLIAEHidden, which are
// documented above.
//
// On input,    itemsPtr must not be NULL.
// On input,   *itemsPtr must be NULL.
// On success, *itemsPtr will be a pointer to a CFArray.
// Or error,   *itemsPtr will be NULL.

WB_EXPORT
OSStatus WBLoginItemAppendItemURL(CFURLRef item, Boolean hidden);
WB_EXPORT
OSStatus WBLoginItemAppendItemFileRef(const FSRef *item, Boolean hidden);
// Add a new login item at the end of the list, using either
// an FSRef or a CFURL.  The hideIt parameter controls whether
// the item is hidden when it's launched.

WB_EXPORT
OSStatus WBLoginItemRemoveItemAtIndex(CFIndex itemIndex);
// Remove a login item.  itemIndex is an index into the array
// of login items as returned by LIAECopyLoginItems.

WB_EXPORT
long WBLoginItemTimeout(void);
WB_EXPORT
void WBLoginItemSetTimeout(long timeout);

#endif /* __WB_LOGIN_ITEMS_H */
