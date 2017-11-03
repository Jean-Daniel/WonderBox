/*
 *  WBFinderSuite.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_FINDER_SUITE_H)
#define __WB_FINDER_SUITE_H 1

#include <WonderBox/WBBase.h>

#include <ApplicationServices/ApplicationServices.h>

WB_EXPORT
CFStringRef const kWBAEFinderBundleIdentifier;

/*!
 @function
 @abstract   This function return Finder selection. As the return value are Finder references, you will probaly change it into
 FSRefs with the function <i>WBAEFinderSelectionToFSRefs</i>.
 @param      items A pointer to an empty ADescList. On return, contains finder selection AEDesc.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEFinderGetSelection(AEDescList *items);

/*!
 @function
 @abstract   Get the current Finder selected items.
 @result     A list of CFURLRef or NULL on error.
 */
WB_EXPORT
CFArrayRef WBAEFinderCopySelection(void);

#pragma mark Current Folder

/*!
 @function
 @abstract  Returns a CFURLRef representation of the path of the current Finder folder or NULL.
 */
WB_EXPORT
CFURLRef WBAEFinderCopyCurrentFolderURL(void);

#pragma mark Sync
WB_EXPORT
OSStatus WBAEFinderSyncItem(const AEDesc *item);
WB_EXPORT
OSStatus WBAEFinderSyncItemAtURL(CFURLRef url);

#pragma mark Reveal Item
WB_EXPORT
OSStatus WBAEFinderRevealItem(const AEDesc *item, Boolean activate) WB_DEPRECATED("NSWorkspace");
WB_EXPORT
OSStatus WBAEFinderRevealItemAtURL(CFURLRef url, Boolean activate) WB_DEPRECATED("NSWorkspace");

#pragma mark Coerce
WB_EXPORT
CFURLRef WBAEFinderCreateFileURLFromObject(const AEDesc* pAEDesc);

// MARK: -
// MARK: Legacy File Types support
//
//WB_EXPORT
//OSStatus WBAEFinderGetObjectAsAlias(const AEDesc* pAEDesc, AliasHandle *alias) WB_DEPRECATED("Bookmark");
//
//WB_EXPORT OSStatus WBAEAddAlias(AppleEvent *theEvent, AEKeyword keyword, AliasHandle alias);
//
//WB_EXPORT OSStatus WBAEAddFSRefAsAlias(AppleEvent *theEvent, AEKeyword keyword, const FSRef *aRef);
//
//// Expect Alias descriptor as input
//WB_EXPORT OSStatus WBAEGetFSRefFromDescriptor(const AEDesc* pAEDesc, FSRef *pRef);
//WB_EXPORT OSStatus WBAEGetFSRefFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, FSRef *pRef);
//WB_EXPORT OSStatus WBAEGetNthFSRefFromDescList(const AEDescList *aList, CFIndex idx, FSRef *pRef);
//
//WB_EXPORT OSStatus WBAECopyAliasFromDescriptor(const AEDesc* pAEDesc, AliasHandle *pAlias);
//WB_EXPORT OSStatus WBAECopyAliasFromAppleEvent(const AppleEvent* anEvent, AEKeyword aKey, AliasHandle *pAlias);
//WB_EXPORT OSStatus WBAECopyNthAliasFromDescList(const AEDescList *aList, CFIndex idx, AliasHandle *pAlias);

#endif /* __WB_FINDER_SUITE_H */
