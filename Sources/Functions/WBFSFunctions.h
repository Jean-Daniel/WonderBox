/*
 *  WBFSFunction.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WBFS_FUNCTIONS_H)
#define __WBFS_FUNCTIONS_H 1

#include <fcntl.h>

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

WB_EXPORT OSStatus WBFSCopyFolderPath(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFStringRef *path);
WB_EXPORT CFStringRef WBFSCopyTemporaryFilePath(FSVolumeRefNum domain, CFStringRef prefix, CFStringRef extension, CFURLPathStyle pathType) WB_OBSOLETE;

/* Format a size and return buffer used length */
WB_EXPORT ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length);

/* Make directory recursive */
WB_EXPORT OSStatus WBFSCreateFolder(CFStringRef path);

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
OSStatus WBFSCreateAliasFile(CFStringRef folder, CFStringRef alias, CFStringRef target);

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
OSStatus WBFSGetTypeAndCreatorAtPath(CFStringRef path, OSType *type, OSType *creator);

enum {
	kWBFSOSTypeIgnore = -1U
};
/* pass kWBFSOSTypeIgnore to keep previous value */
WB_EXPORT
OSStatus WBFSSetTypeAndCreator(const FSRef *ref, OSType type, OSType creator);
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtURL(CFURLRef url, OSType type, OSType creator);
WB_EXPORT
OSStatus WBFSSetTypeAndCreatorAtPath(CFStringRef path, OSType type, OSType creator);

#if defined(__WB_OBJC__)

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
NSString *WBFSFindFolder(OSType folderType, FSVolumeRefNum domain, bool create) {
  CFStringRef path = NULL;
  if (noErr == WBFSCopyFolderPath(folderType, domain, create, &path))
    return WBCFAutorelease(path);
  return nil;
}

#endif /* __WB_OBJC__ */

#endif /* __WBFS_FUNCTIONS_H */
