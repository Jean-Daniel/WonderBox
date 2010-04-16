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

#include <fcntl.h>

__BEGIN_DECLS

#pragma mark -
#pragma mark File System C API

/* Private Finder flag */
enum {
  kIsExtensionHidden = 0x0010,
};

WB_EXPORT OSStatus WBFSRefIsFolder(const FSRef *objRef, Boolean *isFolder);
WB_EXPORT OSStatus WBFSRefIsVisible(const FSRef *objRef, Boolean *isVisible);
WB_EXPORT OSStatus WBFSRefHasCustomIcon(const FSRef *objRef, Boolean *hasIcon);
WB_EXPORT OSStatus WBFSRefIsRootDirectory(const FSRef *objRef, Boolean *isRoot);

WB_EXPORT OSStatus WBFSRefCopyFileSystemPath(const FSRef *ref, CFStringRef *path);
WB_EXPORT OSStatus WBFSRefCreateFromFileSystemPath(CFStringRef string, OptionBits options, FSRef *ref, Boolean *isDirectory);

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

WB_EXPORT OSStatus WBFSCopyFolderPath(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFStringRef *path) WB_OBSOLETE;
// look on the same volume than anURL
WB_EXPORT OSStatus WBFSCopyFolderPathForURL(OSType folderType, CFURLRef anURL, bool createFolder, CFStringRef *path) WB_OBSOLETE;

/* Format a size and return buffer used length */
WB_EXPORT ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length);

/* Make directory recursive. Use NSFileManager instead */
WB_EXPORT OSStatus WBFSCreateFolder(CFStringRef path) DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER;

/*!
 @function 
 @param willDeleteObject return <code>false</code> to abort operation, <code>true</code> to continue.
 */
WB_EXPORT OSStatus WBFSDeleteFolder(const FSRef *folder, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt);
WB_EXPORT OSStatus WBFSDeleteFolderAtPath(CFStringRef fspath, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt);
/* delete an object using the posix convention (ignore busy files), and unlock it if needed */
WB_EXPORT OSStatus WBFSForceDeleteObject(const FSRef *folder);

/*!
 @function WBFSCreateAliasFile
 @param folder Destination folder.
 @param alias Path of the new alias file.
 @param target The file pointed by the new alias.
 */
WB_EXPORT
OSStatus WBFSCreateAliasFile(CFStringRef folder, CFStringRef alias, CFStringRef target) WB_OBSOLETE;

WB_EXPORT
OSStatus WBFSGetVolumeSize(FSVolumeRefNum volume, UInt64 *size, CFIndex *files, CFIndex *folders);
WB_EXPORT
OSStatus WBFSGetFolderSize(FSRef *folder, UInt64 *lsize, UInt64 *psize, CFIndex *files, CFIndex *folders);

WB_EXPORT
OSStatus WBFSGetVolumeInfo(FSRef *object, FSVolumeRefNum *actualVolume, 
                           FSVolumeInfoBitmap whichInfo, FSVolumeInfo *info, HFSUniStr255 *volumeName, FSRef *rootDirectory);

/* OSTypes */
WB_EXPORT
OSStatus WBFSGetTypeAndCreator(const FSRef *ref, OSType *type, OSType *creator);
WB_EXPORT
OSStatus WBFSGetTypeAndCreatorAtURL(CFURLRef url, OSType *type, OSType *creator);
WB_EXPORT
OSStatus WBFSGetTypeAndCreatorAtPath(CFStringRef path, OSType *type, OSType *creator) WB_OBSOLETE;

enum {
	kWBFSOSTypeIgnore = -1U
};
/* pass kWBFSOSTypeIgnore to keep previous value */
WB_EXPORT
OSStatus WBFSSetTypeAndCreator(const FSRef *ref, OSType type, OSType creator);
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtURL(CFURLRef url, OSType type, OSType creator);
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtPath(CFStringRef path, OSType type, OSType creator) WB_OBSOLETE;

#if defined(__OBJC__)

@interface NSString (WBFileSystem)
+ (NSString *)stringFromFSRef:(const FSRef *)ref;
- (NSString *)initFromFSRef:(const FSRef *)ref;

+ (NSString *)stringWithFileSystemRepresentation:(const char *)path length:(NSUInteger)length;

/* traverse link by default */
- (BOOL)getFSRef:(FSRef *)ref;
- (BOOL)getFSRef:(FSRef *)ref traverseLink:(BOOL)flag;

@end

@interface NSFileManager (WBResolveAlias)
- (BOOL)isAliasFileAtPath:(NSString *)path;
- (NSString *)resolveAliasFileAtPath:(NSString *)alias isFolder:(BOOL *)isFolder;
@end

#pragma mark -
WB_INLINE
NSURL *WBFSFindFolder(OSType folderType, FSVolumeRefNum domain, bool create) {
  CFURLRef path = NULL;
  if (noErr == WBFSCopyFolderURL(folderType, domain, create, &path))
    return WBCFAutorelease(path);
  return nil;
}

#endif /* __OBJC__ */

__END_DECLS

#endif /* __WB_FS_FUNCTIONS_H */
