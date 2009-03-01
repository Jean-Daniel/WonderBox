/*
 *  WBFinderSuite.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

WB_EXPORT
OSType WBAEFinderSignature;

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
 @abstract   Change a AEDescList representing Finder selection (obtains from <i>WBAEGetFinderSelection</i>) into an
 array of FSRef.
 @param      items AEDescList representing Finder items.
 @param		selection A pointer to an Array of FSRef. On return contains <i>itemsCount</i> converted items.
 @param		maxCount Size of <i>selection</i> array.
 @param		itemsCount Count of items successfully converted.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEFinderSelectionToFSRefs(AEDescList *items, FSRef *selection, CFIndex maxCount, CFIndex *itemsCount);

#pragma mark Current Folder
/*!
 @function
 @abstract   Return a FSRef pointing on the Finder current folder, i.e. that will be choose if we create a new Folder for example.
 @param      folder On return, a FSRef pointing on the Finder current folder.
 @result     A result code.
 */
WB_EXPORT
OSStatus WBAEFinderGetCurrentFolder(FSRef *folder);

/*!
 @function
 @abstract	Returns a CFURLRef representation of the path of the current Finder folder or NULL.
 */
WB_EXPORT
CFURLRef WBAEFinderCopyCurrentFolderURL(void);

/*!
 @function
 @abstract	Returns a CFStringRef representation of the POSIX path of the current Finder folder or NULL.
 */
WB_EXPORT 
CFStringRef WBAEFinderCopyCurrentFolderPath(void);

#pragma mark Sync
WB_EXPORT 
OSStatus WBAEFinderSyncItem(const AEDesc *item);
WB_EXPORT 
OSStatus WBAEFinderSyncFSRef(const FSRef *aRef);
WB_EXPORT 
OSStatus WBAEFinderSyncItemAtURL(CFURLRef url);

#pragma mark Reveal Item
WB_EXPORT 
OSStatus WBAEFinderRevealItem(const AEDesc *item, Boolean activate);
WB_EXPORT 
OSStatus WBAEFinderRevealFSRef(const FSRef *aRef, Boolean activate);
WB_EXPORT 
OSStatus WBAEFinderRevealItemAtURL(CFURLRef url, Boolean activate);

#pragma mark Coerce
WB_EXPORT
OSStatus WBAEFinderGetObjectAsFSRef(const AEDesc* pAEDesc, FSRef *file);
WB_EXPORT
OSStatus WBAEFinderGetObjectAsAlias(const AEDesc* pAEDesc, AliasHandle *alias);

