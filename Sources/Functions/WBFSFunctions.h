/*
 *  WBFSFunction.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_FS_FUNCTIONS_H)
#define __WB_FS_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>

#include <CoreServices/CoreServices.h>

#include <fcntl.h>

__BEGIN_DECLS

#pragma mark -
#pragma mark File System C API

/* Private Finder flag */
enum {
  kIsExtensionHidden = 0x0010,
};

/*!
 @return true if both URL points to the same file.
 */
WB_EXPORT
bool WBFSCompareURLs(CFURLRef url1, CFURLRef url2);

WB_EXPORT OSStatus WBFSRefIsFolder(const FSRef *objRef, Boolean *isFolder) WB_DEPRECATED("Use URL API");
WB_EXPORT OSStatus WBFSRefIsVisible(const FSRef *objRef, Boolean *isVisible) WB_DEPRECATED("Use URL API");
WB_EXPORT OSStatus WBFSRefHasCustomIcon(const FSRef *objRef, Boolean *hasIcon) WB_DEPRECATED("Use URL API");
WB_EXPORT OSStatus WBFSRefIsRootDirectory(const FSRef *objRef, Boolean *isRoot) WB_DEPRECATED("Use URL API");

WB_EXPORT OSStatus WBFSRefCopyFileSystemPath(const FSRef *ref, CFStringRef *path) WB_DEPRECATED("Use URL API");
WB_EXPORT OSStatus WBFSRefCreateFromFileSystemPath(CFStringRef string, OptionBits options, FSRef *ref, Boolean *isDirectory) WB_DEPRECATED("Use URL API");

// same as FSGetHFSUniStrFromString, but convert ':' into '/'
WB_EXPORT OSStatus WBFSGetHFSUniStrFromString(CFStringRef string, HFSUniStr255 *filename);
WB_EXPORT CFStringRef WBFSCreateStringFromHFSUniStr(CFAllocatorRef alloc, const HFSUniStr255 *uniStr);

WB_EXPORT OSStatus WBFSGetVolumeForURL(CFURLRef anURL, FSVolumeRefNum *volume);

WB_EXPORT OSStatus WBFSCopyFolderURL(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFURLRef *path);
// look on the same volume than anURL
WB_EXPORT OSStatus WBFSCopyFolderURLForURL(OSType folderType, CFURLRef anURL, bool createFolder, CFURLRef *path);

enum {
  kWBFSTemporaryItemIsFolder = 1 << 0,
  kWBFSTemporaryItemAutoDelete = 1 << 1,
  kWBFSTemporaryItemUseSystemVolumeOnError = 1 << 2, // on error, instead of returning nil, will use the system volume
};
WB_EXPORT OSStatus WBFSCreateTemporaryURL(FSVolumeRefNum volume, CFURLRef *result, CFOptionFlags flags);

// create temporary URL on the same volume than anURL (suitable for exchangedata).
WB_EXPORT OSStatus WBFSCreateTemporaryURLForURL(CFURLRef anURL, CFURLRef *result, CFOptionFlags flags);

WB_EXPORT OSStatus WBFSCopyFolderPath(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFStringRef *path) WB_DEPRECATED("WBFSCopyFolderURL");
// look on the same volume than anURL
WB_EXPORT OSStatus WBFSCopyFolderPathForURL(OSType folderType, CFURLRef anURL, bool createFolder, CFStringRef *path) WB_DEPRECATED("WBFSCopyFolderURLForURL");

/* Format a size and return buffer used length */
WB_EXPORT ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length);

WB_EXPORT OSStatus WBFSDeleteEmptyFolder(const FSRef *aFolder) WB_DEPRECATED("Use URL API");
WB_EXPORT OSStatus WBFSDeleteEmptyFolderAtURL(CFURLRef anURL);

/*!
 @function
 @param willDeleteObject return <code>false</code> to abort operation, <code>true</code> to continue.
 */
WB_EXPORT OSStatus WBFSDeleteFolder(const FSRef *folder, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt) WB_DEPRECATED("Use NSWorkspace async API");
WB_EXPORT OSStatus WBFSDeleteFolderAtPath(CFStringRef fspath, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt) WB_DEPRECATED("Use NSWorkspace async API");
/* delete an object using the posix convention (ignore busy files), and unlock it if needed */
WB_EXPORT OSStatus WBFSForceDeleteObject(const FSRef *folder) WB_DEPRECATED("FSRef is deprecated");

/*!
 @function WBFSCreateAliasFile
 @param folder Destination folder.
 @param alias Path of the new alias file.
 @param target The file pointed by the new alias.
 */
WB_EXPORT
OSStatus WBFSCreateAliasFile(CFStringRef folder, CFStringRef alias, CFStringRef target) WB_DEPRECATED("Use bookmark API");

/*!
 @function
 @abstract Create a bookmark (alias) file that point to targetURL.
 @param bookmarkName NULL to use displauy name of the target
 */
//WB_EXPORT
//OSStatus WBFSCreateBookmarkFile(CFURLRef targetURL, CFURLRef folder, CFStringRef bookmarkName, CFErrorRef *error);

WB_EXPORT
OSStatus WBFSGetVolumeSize(FSVolumeRefNum volume, UInt64 *size, UInt32 *files, UInt32 *folders);
WB_EXPORT
OSStatus WBFSGetFolderSize(FSRef *folder, UInt64 *lsize, UInt64 *psize, UInt32 *files, UInt32 *folders) WB_DEPRECATED("Use URL API");

WB_EXPORT
OSStatus WBFSGetVolumeInfo(FSRef *object, FSVolumeRefNum *actualVolume,
                           FSVolumeInfoBitmap whichInfo, FSVolumeInfo *info, HFSUniStr255 *volumeName, FSRef *rootDirectory) WB_DEPRECATED("Use URL API");

/* OSTypes */
WB_EXPORT
OSStatus WBFSGetTypeAndCreator(const FSRef *ref, OSType *type, OSType *creator) WB_DEPRECATED("Use URL API");
WB_EXPORT
OSStatus WBFSGetTypeAndCreatorAtURL(CFURLRef url, OSType *type, OSType *creator) WB_DEPRECATED("Type and creator !");
WB_EXPORT
OSStatus WBFSGetTypeAndCreatorAtPath(CFStringRef path, OSType *type, OSType *creator) WB_DEPRECATED("Type and creator !");

#define kWBFSOSTypeIgnore (OSType)-1

/* pass kWBFSOSTypeIgnore to keep previous value */
WB_EXPORT
OSStatus WBFSSetTypeAndCreator(const FSRef *ref, OSType type, OSType creator) WB_DEPRECATED("Creator is obsolete");
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtURL(CFURLRef url, OSType type, OSType creator) WB_DEPRECATED("Creator is obsolete");
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtPath(CFStringRef path, OSType type, OSType creator) WB_DEPRECATED("WBFSSetTypeAndCreatorAtURL");

#if defined(__OBJC__)

#import <Foundation/Foundation.h>

@interface NSString (WBFileSystem)
+ (NSString *)stringFromFSRef:(const FSRef *)ref WB_DEPRECATED("Use URL API");

+ (NSString *)stringWithFileSystemRepresentation:(const char *)path length:(NSUInteger)length  WB_DEPRECATED("Use URL API");

// same as fileSystemRepresentation but returns nil instead of throwing an exception
- (const char *)safeFileSystemRepresentation;

/* traverse link by default */
- (BOOL)getFSRef:(FSRef *)ref WB_DEPRECATED("Use URL API");
- (BOOL)getFSRef:(FSRef *)ref traverseLink:(BOOL)flag WB_DEPRECATED("Use URL API");

@end

#pragma mark -
WB_INLINE
NSURL *WBFSFindFolder(OSType folderType, FSVolumeRefNum domain, bool create) {
  CFURLRef path = NULL;
  if (noErr == WBFSCopyFolderURL(folderType, domain, create, &path))
    return SPXCFURLBridgingRelease(path);
  return nil;
}

#endif /* __OBJC__ */

__END_DECLS

#endif /* __WB_FS_FUNCTIONS_H */
