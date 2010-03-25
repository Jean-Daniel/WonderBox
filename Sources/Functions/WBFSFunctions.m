/*
 *  WBFSFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBFSFunctions.h)

#include <sys/stat.h>

#pragma mark File System Representation

#pragma mark NSString Extension
@implementation NSString (WBFileSystem)

+ (NSString *)stringFromFSRef:(const FSRef *)ref {
  CFStringRef str = NULL;
  if (noErr == WBFSRefCopyFileSystemPath(ref, &str))
    return WBCFAutorelease(str);
  return nil;
}

- (NSString *)initFromFSRef:(const FSRef *)ref {
  /* 
  Is it safe to release the string cluster placeholder ?
   [self release]; 
   */
  CFStringRef str = NULL;
  if (noErr == WBFSRefCopyFileSystemPath(ref, &str))
    return (id)str;
  return nil;  
}

+ (NSString *)stringWithFileSystemRepresentation:(const char *)path length:(NSUInteger)length {
  return [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:length];
}

- (BOOL)getFSRef:(FSRef *)ref {
  return [self getFSRef:ref traverseLink:YES];
}

- (BOOL)getFSRef:(FSRef *)ref traverseLink:(BOOL)flag {
  OptionBits opts = flag ? kFSPathMakeRefDefaultOptions : kFSPathMakeRefDoNotFollowLeafSymlink;
  return noErr == FSPathMakeRefWithOptions((const UInt8 *)[self fileSystemRepresentation], opts, ref, NULL);
}

@end

#pragma mark NSFileManager Extension
@implementation NSFileManager (WBResolveAlias)

- (BOOL)isAliasFileAtPath:(NSString *)path {
  FSRef file;
  Boolean result;
  if ([path getFSRef:&file traverseLink:NO]) {
    Boolean isFolder;
    if (noErr == FSIsAliasFile(&file, &result, &isFolder)) {
      return result;
    }
  }
  return NO;
}

- (NSString *)resolveAliasFileAtPath:(NSString *)alias isFolder:(BOOL *)isFolder {
  NSString *path = nil;
  FSRef file;
  if ([alias getFSRef:&file traverseLink:NO]) {
    OSStatus err;
    Boolean aliased, folder;
    err = FSResolveAliasFile(&file, YES, &folder, &aliased);
    if (noErr == err && aliased) {
      if (isFolder)
        *isFolder = folder;
      path = [NSString stringFromFSRef:&file];
    }
  }
  return path;
}

@end

#pragma mark -
#pragma mark File System
static 
OSStatus _WBFSRefGetPath(const FSRef *ref, OSStatus (*callback)(const char *path, void *ctxt), void *ctxt) {
  /* facility to get a path from a fsref */
  UInt8 buffer[2048];
  UInt8 *path = buffer;
  UInt32 length = 4096;
  
  OSStatus err = FSRefMakePath(ref, path, 2048);
  /* If path is too long */
  while (pathTooLongErr == err) {
    if (buffer == path) {
      path = malloc(length * sizeof(UInt8));
    } else {
      length *= 2;
      path = realloc(path, length * sizeof(UInt8));
    }
    err = FSRefMakePath(ref, path, length);
  }
  if (noErr == err) {
    err = callback((char *)path, ctxt);
  }
  /* Free if needed */
  if (buffer != path)
    free(path);
  
  return err;
}


OSStatus WBFSRefIsFolder(const FSRef *objRef, Boolean *isFolder) {
  if (!isFolder) return paramErr;
  
  OSStatus err;
  FSCatalogInfo catalogInfo;
  err = FSGetCatalogInfo(objRef, kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, NULL);
  if (noErr == err) {
    *isFolder = (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0;
  }
  return err;
}

OSStatus WBFSRefIsVisible(const FSRef *objRef, Boolean *isVisible) {
  if (!isVisible) return paramErr;

  OSStatus err;
  FSCatalogInfo catalogInfo;
  err = FSGetCatalogInfo(objRef, kFSCatInfoFinderInfo | kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, NULL);
  require_noerr_string(err, bail, "Error while getting catalog info.");
  
  if ((catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0) {
    FolderInfo *folInfo = (FolderInfo *)catalogInfo.finderInfo;
    *isVisible = (folInfo->finderFlags & kIsInvisible) == 0;
  } else {
    FileInfo *finInfo = (FileInfo *)catalogInfo.finderInfo;
    *isVisible = (finInfo->finderFlags & kIsInvisible) == 0;
  }
  
bail:
  return err;
}

OSStatus WBFSRefHasCustomIcon(const FSRef *objRef, Boolean *hasIcon) {
  if (!hasIcon) return paramErr;

  OSStatus err;
  Boolean isFolder;
  FSCatalogInfo catInfo;
  
  err = FSGetCatalogInfo(objRef, kFSCatInfoFinderInfo | kFSCatInfoNodeFlags, &catInfo , NULL, NULL, NULL);
  if (noErr == err) {
    isFolder = (catInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0;
    if (isFolder) {
      FileInfo *fileInfo = (FileInfo *)catInfo.finderInfo;
      *hasIcon = (fileInfo->finderFlags & kHasCustomIcon) != 0;
    } else {
      FolderInfo *folderInfo = (FolderInfo *)catInfo.finderInfo;
      *hasIcon = (folderInfo->finderFlags & kHasCustomIcon) != 0;
    }
  }
  return err;
}

OSStatus WBFSRefIsRootDirectory(const FSRef *objRef, Boolean *isRoot) {
  if (!isRoot) return paramErr;
  
  OSStatus err;
  FSCatalogInfo catalogInfo;
  err = FSGetCatalogInfo(objRef, kFSCatInfoNodeID, &catalogInfo, NULL, NULL, NULL);
  if (noErr == err) 
    *isRoot = (catalogInfo.nodeID == fsRtDirID);
  
  return err;
}

static
OSStatus _WBFSRefCopyFileSystemPath(const char *path, void *ctxt) {
  CFStringRef *str = (CFStringRef *)ctxt;
  *str = CFStringCreateWithFileSystemRepresentation(kCFAllocatorDefault, path);
  return *str ? noErr : coreFoundationUnknownErr;
}

OSStatus WBFSRefCopyFileSystemPath(const FSRef *ref, CFStringRef *string) {
  if (!string || *string != NULL) return paramErr;
  
  return _WBFSRefGetPath(ref, _WBFSRefCopyFileSystemPath, string);
}

OSStatus WBFSRefCreateFromFileSystemPath(CFStringRef string, OptionBits options, FSRef *ref, Boolean *isDirectory) {
  if (!string || !ref) return paramErr;
  
  char buffer[2048];
  char *path = buffer;
  OSStatus err = noErr;
  /* Adjust buffer size */
  CFIndex maximum = CFStringGetMaximumSizeOfFileSystemRepresentation(string);
  if (maximum > 2048) {
    path = malloc(maximum * sizeof(char));
  }
  
  if (!CFStringGetFileSystemRepresentation(string, path, maximum))
    err = coreFoundationUnknownErr;
  
  if (noErr == err)
    err = FSPathMakeRefWithOptions((UInt8 *)path, options, ref, isDirectory);
  
  if (path != buffer)
    free(path);
  
  return err;
}

#pragma mark Folders
OSStatus WBFSGetVolumeSize(FSVolumeRefNum volume, UInt64 *size, CFIndex *files, CFIndex *folders) {
  if (!size && !files && !folders) return paramErr;
  
  FSVolumeInfo info;
  OSStatus err = FSGetVolumeInfo(volume, 0, NULL, kFSVolInfoSizes | kFSVolInfoDirCount | kFSVolInfoFileCount, &info, NULL, NULL);
  require_noerr(err, bail);
  
  if (size) *size = info.totalBytes - info.freeBytes;
  if (files) *files = info.fileCount;
  if (folders) *folders = info.folderCount;
  
bail:
    return err;
}

#define BULK_SIZE 128
static
OSStatus _WBFSGetFolderSize(FSRef *folder, UInt64 *lsize, UInt64 *psize, CFIndex *files, CFIndex *folders) {
  FSIterator iter;
  OSStatus err = FSOpenIterator(folder, kFSIterateFlat, &iter);
  if (noErr == err) {
    ItemCount count = BULK_SIZE;
    FSRef *refs = malloc(BULK_SIZE * sizeof(*refs));
    FSCatalogInfo *infos = malloc(BULK_SIZE * sizeof(*infos));
    FSCatalogInfoBitmap bitmap = kFSCatInfoNodeFlags;
    if (lsize || psize)
      bitmap |= kFSCatInfoDataSizes | kFSCatInfoRsrcSizes;
    while (noErr == err) {
      err = FSGetCatalogInfoBulk(iter, BULK_SIZE, &count, NULL, bitmap, infos, refs, NULL, NULL);
      if (noErr == err || errFSNoMoreItems == err) {
        while (count-- > 0) {
          if (lsize) (*lsize) += infos[count].dataLogicalSize + infos[count].rsrcLogicalSize;
          if (psize) (*psize) += infos[count].dataPhysicalSize + infos[count].rsrcPhysicalSize;
          if (infos[count].nodeFlags & kFSNodeIsDirectoryMask) {
            if (folders) (*folders)++;
            err = _WBFSGetFolderSize(&refs[count], lsize, psize, files, folders);
          } else {
            if (files) (*files)++;
          }
        }
      }
    }
    FSCloseIterator(iter);
    free(infos);
    free(refs);
  }
  /* cleanup expected error */
  if (errFSNoMoreItems == err) 
    err = noErr;
  return err;
}

OSStatus WBFSGetFolderSize(FSRef *folder, UInt64 *lsize, UInt64 *psize, CFIndex *files, CFIndex *folders) {
  if (!lsize && !psize && !files && !folders) return paramErr;
  
  FSCatalogInfo info;
  OSStatus err = FSGetCatalogInfo(folder, kFSCatInfoNodeFlags | kFSCatInfoNodeID | kFSCatInfoVolume, &info, NULL, NULL, NULL);
  require_noerr(err, bail);
  
  if (!(info.nodeFlags & kFSNodeIsDirectoryMask))
    return errFSNotAFolder;
  
  if (fsRtDirID == info.nodeID) {
    UInt64 size = 0;
    err = WBFSGetVolumeSize(info.volume, &size, files, folders);
    if (noErr == err) {
      if (lsize) *lsize = size;
      if (psize) *psize = size;
    }
  } else {
    if (lsize) *lsize = 0;
    if (psize) *psize = 0;
    if (files) *files = 0;
    if (folders) *folders = 0;
    err = _WBFSGetFolderSize(folder, lsize, psize, files, folders);
  }
  
bail:
    return err;
}

OSStatus WBFSGetVolumeInfo(FSRef *object, FSVolumeRefNum *actualVolume, 
                           FSVolumeInfoBitmap whichInfo, FSVolumeInfo *info, HFSUniStr255 *volumeName, FSRef *rootDirectory) {
  if (!object) return paramErr;
  
  FSCatalogInfo fsinfo;
  OSStatus err = FSGetCatalogInfo(object, kFSCatInfoVolume, &fsinfo, NULL, NULL, NULL);
  require_noerr(err, bail);
  
  err = FSGetVolumeInfo(fsinfo.volume, 0, actualVolume, whichInfo, info, volumeName, rootDirectory);
  require_noerr(err, bail);
  
bail:
    return err;
}

#pragma mark -
#pragma mark OSTypes
OSStatus WBFSGetTypeAndCreator(const FSRef *ref, OSType *type, OSType *creator) {
  if (!ref) return paramErr;
  if (!type && !creator) return paramErr;
	
  FSCatalogInfo info;
  OSStatus err = FSGetCatalogInfo(ref, kFSCatInfoFinderInfo | kFSCatInfoNodeFlags, &info, NULL, NULL, NULL);
  if (noErr == err) {
    if (info.nodeFlags & kFSNodeIsDirectoryMask) {
      err = notAFileErr;
    } else {
      FileInfo *finfo = (FileInfo *)info.finderInfo;
      if (type) *type = finfo->fileType;
      if (creator) *creator = finfo->fileCreator;
    }
  }
  return err;
}

OSStatus WBFSGetTypeAndCreatorAtURL(CFURLRef url, OSType *type, OSType *creator) {
  if (!url) return paramErr;
  if (!type && !creator) return paramErr;
	
	FSRef ref;
	if (!CFURLGetFSRef(url, &ref)) return coreFoundationUnknownErr;
	return WBFSGetTypeAndCreator(&ref, type, creator);
}

OSStatus WBFSGetTypeAndCreatorAtPath(CFStringRef path, OSType *type, OSType *creator) {
	if (!path) return paramErr;
  if (!type && !creator) return paramErr;
	
  FSRef ref;
  Boolean isDir;
  OSStatus err = WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &ref, &isDir);
  if (noErr == err) {
    if (isDir)
      err = notAFileErr;
    else
      err = WBFSGetTypeAndCreator(&ref, type, creator);
  }
  return err;
}

OSStatus WBFSSetTypeAndCreator(const FSRef *ref, OSType type, OSType creator) {
	if (!ref) return paramErr;
	if (kWBFSOSTypeIgnore == type && kWBFSOSTypeIgnore == creator) return paramErr;
	
  FSCatalogInfo info;
  OSStatus err = FSGetCatalogInfo(ref, kFSCatInfoFinderInfo | kFSCatInfoNodeFlags, &info, NULL, NULL, NULL);
	if (noErr == err) {
		if (info.nodeFlags & kFSNodeIsDirectoryMask) {
      err = notAFileErr;
    } else {
      FileInfo *finfo = (FileInfo *)info.finderInfo;
			if (kWBFSOSTypeIgnore != type) finfo->fileType = type;
			if (kWBFSOSTypeIgnore != creator) finfo->fileCreator = creator;
			err = FSSetCatalogInfo(ref, kFSCatInfoFinderInfo, &info);
    }
	}
	return err;
}

OSStatus WBFSSetTypeAndCreatorAtURL(CFURLRef url, OSType type, OSType creator) {
	if (!url) return paramErr;
	if (kWBFSOSTypeIgnore == type && kWBFSOSTypeIgnore == creator) return paramErr;
	
	FSRef ref;
	if (!CFURLGetFSRef(url, &ref)) return coreFoundationUnknownErr;
	return WBFSSetTypeAndCreator(&ref, type, creator);	
}

OSStatus WBFSSetTypeAndCreatorAtPath(CFStringRef path, OSType type, OSType creator) {
	if (!path) return paramErr;
	if (kWBFSOSTypeIgnore == type && kWBFSOSTypeIgnore == creator) return paramErr;
	
	FSRef ref;
  Boolean isDir;
  OSStatus err = WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &ref, &isDir);
  if (noErr == err) {
    if (isDir)
      err = notAFileErr;
    else
      err = WBFSSetTypeAndCreator(&ref, type, creator);
  }
  return err;
}

#pragma mark Misc
ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length) {
  if (!unit || !buffer) return paramErr;
  
  if (size < ((UInt64)1 << 10))
    return snprintf(buffer, length, "%qu %s", size, unit);
  
  /* Kilo */
  if (size < ((UInt64)1 << 20))
    return snprintf(buffer, length, "%.*f K%s", (int)precision, (double)size / ((UInt64)1 << 10), unit);
  /* Mega */
  if (size < ((UInt64)1 << 30))
    return snprintf(buffer, length, "%.*f M%s", (int)precision, (double)size / ((UInt64)1 << 20), unit);
  /* Giga */
  if (size < ((UInt64)1 << 40))
    return snprintf(buffer, length, "%.*f G%s", (int)precision, (double)size / ((UInt64)1 << 30), unit);
  /* Tera */
  if (size < ((UInt64)1 << 50))
    return snprintf(buffer, length, "%.*f T%s", (int)precision, (double)size / ((UInt64)1 << 40), unit);
  /* Peta */
  if (size < ((UInt64)1 << 60))
    return snprintf(buffer, length, "%.*f P%s", (int)precision, (double)size / ((UInt64)1 << 50), unit);
  /* Exa */
  return snprintf(buffer, length, "%.*f E%s", (int)precision, (double)size / ((UInt64)1 << 60), unit);    
}

OSStatus WBFSCreateFolder(CFStringRef path) {
  if (!path || !CFStringGetLength(path)) return paramErr;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  BOOL isDirectory;
  NSFileManager *manager = [NSFileManager defaultManager];
  
  if ([manager fileExistsAtPath:(id)path isDirectory:&isDirectory]) {
    WBAutoreleasePoolDrain(pool);
    return isDirectory ? noErr : errFSNotAFolder;
  }
  
  NSMutableArray *components = [[NSMutableArray alloc] init];
  
  /* Replace . and .. in path, and convert it into c string */
  const char *characters = [(id)path fileSystemRepresentation];
  NSString *subpath = [NSString stringWithFileSystemRepresentation:characters length:strlen(characters)];
  while ([subpath length] && ![manager fileExistsAtPath:subpath isDirectory:&isDirectory]) {
    [components addObject:subpath];
    subpath = [subpath stringByDeletingLastPathComponent];
  }
  
  OSStatus err = noErr;
  /* If a subpath component is not a directory */
  if ([subpath length] && !isDirectory) {
    err = dupFNErr;
  }
  require_noerr(err, dispose);
  
  NSUInteger count = [components count];
  while (noErr == err && count-- > 0) {
    subpath = [components objectAtIndex:count];
    err = [manager createDirectoryAtPath:subpath attributes:NULL] ? noErr : dirNFErr;
  }

dispose:
  [components release];
  WBAutoreleasePoolDrain(pool);
  
  return err;
}

static 
OSStatus _WBFSForceDeletePath(const char *path, void *ctxt) {
  struct stat info;
  memset(&info, 0, sizeof(info));
  int err = lstat(path, &info);
  if (0 == err) {
    if (S_ISDIR(info.st_mode))
      err = rmdir(path);
    else
      err = unlink(path);
  }
  if (0 != err) {
    /* basic error mapping */
    switch (errno) {
      default:
        return kPOSIXErrorBase + errno;
      case EPERM:
      case EACCES:
        return permErr;
      case ENAMETOOLONG:
        return errFSNameTooLong;
    }
  }
  return noErr;
}

WB_INLINE
OSStatus __WBFSForceDeleteObject(const FSRef *object) {
  /* delete a busy file */
  return _WBFSRefGetPath(object, _WBFSForceDeletePath, NULL);
}

OSStatus WBFSForceDeleteObject(const FSRef *object) {
  if (!object) return paramErr;
  
  FSCatalogInfo info;
  OSStatus err = FSGetCatalogInfo(object, kFSCatInfoNodeFlags, &info, NULL, NULL, NULL);
  if (noErr == err) {
    if (info.nodeFlags & kFSNodeLockedMask) {
      info.nodeFlags &= ~kFSNodeLockedMask;
      /* result can be safely ignored as the following delete operation will failed if an error occured */
      FSSetCatalogInfo(object, kFSCatInfoNodeFlags, &info);
    }
    err = FSDeleteObject(object);
    if (fBsyErr == err)
      err = __WBFSForceDeleteObject(object);
  }
  return err;
}

OSStatus WBFSDeleteFolder(const FSRef *folder, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt) {
  if (!folder) return paramErr;
  
  FSIterator iter;
  OSStatus err = FSOpenIterator(folder, kFSIterateFlat | kFSIterateDelete, &iter);
  if (noErr == err) {
    ItemCount count = BULK_SIZE;
    FSRef *refs = malloc(BULK_SIZE * sizeof(*refs));
    FSCatalogInfo *infos = malloc(BULK_SIZE * sizeof(*infos));
    while (noErr == err) {
      err = FSGetCatalogInfoBulk(iter, BULK_SIZE, &count, NULL, kFSCatInfoNodeFlags, infos, refs, NULL, NULL);
      if (noErr == err || errFSNoMoreItems == err) {
        while (count-- > 0) {
          /* unlock item if needed */
          if (infos[count].nodeFlags & kFSNodeLockedMask) {
            infos[count].nodeFlags &= ~kFSNodeLockedMask;
            /* result can be safely ignored as the following delete operation will failed if an error occured */
            FSSetCatalogInfo(&refs[count], kFSCatInfoNodeFlags, &infos[count]);
          }
          
          if (infos[count].nodeFlags & kFSNodeIsDirectoryMask) {
            err = WBFSDeleteFolder(&refs[count], willDeleteObject, ctxt);
          } else {
            if (willDeleteObject && !willDeleteObject(&refs[count], ctxt))
              err = userCanceledErr;
            
            if (noErr == err || errFSNoMoreItems == err) {
              err = FSDeleteObject(&refs[count]);
              if (fBsyErr == err) err = __WBFSForceDeleteObject(&refs[count]);
            }
          }
        }
      }
    }
    verify_noerr(FSCloseIterator(iter));
    free(infos);
    free(refs);
  }
  /* reset expected error */
  if (errFSNoMoreItems == err)
    err = noErr;
  
  /* finaly, delete the folder */
  if (noErr == err && willDeleteObject && !willDeleteObject(folder, ctxt))
    err = userCanceledErr;
  if (noErr == err) {
    err = FSDeleteObject(folder);
    if (fBsyErr == err) err = __WBFSForceDeleteObject(folder);
  }
  
  return err;
}
OSStatus WBFSDeleteFolderAtPath(CFStringRef fspath, bool (*willDeleteObject)(const FSRef *, void *ctxt), void *ctxt) {
  if (!fspath) return paramErr;
  
  FSRef fref;
  OSStatus err = WBFSRefCreateFromFileSystemPath(fspath, kFSPathMakeRefDoNotFollowLeafSymlink, &fref, NULL);
  if (noErr == err)
    err = WBFSDeleteFolder(&fref, willDeleteObject, ctxt);
  return err;
}

/* MARK: Find Folder */
OSStatus WBFSCopyFolderURL(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFURLRef *path) {
  if (!path) return paramErr;
  
  FSRef folder;
  OSStatus err = FSFindFolder(domain,
                              folderType,
                              createFolder ? kCreateFolder : kDontCreateFolder,
                              &folder);
  if (noErr == err) {
    *path = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
    if (!*path)
      err = coreFoundationUnknownErr;
  }
  return err;
}
// look on the same volume than anURL
OSStatus WBFSCopyFolderURLForURL(OSType folderType, CFURLRef anURL, bool createFolder, CFURLRef *path) {
  if (!anURL || !path) return paramErr;
  
  FSRef ref;
  Boolean ok = CFURLGetFSRef(anURL, &ref);
  if (!ok) {
    // We may want a folder for an url that does not exists yet. so check parents until we find one that exists.
    CFURLRef parent = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, anURL);
    while (parent && !(ok = CFURLGetFSRef(parent, &ref))) {
      CFURLRef previous = parent;
      parent = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, parent);
      if (parent && CFEqual(parent, previous)) { // deleting last path component returns the same path -> break.
        CFRelease(parent);
        parent = NULL;
      }
      CFRelease(previous);
    }
    if (parent)
      CFRelease(parent);
  }
  
  if (!ok)
    return coreFoundationUnknownErr; // probably fnfErr
  
  FSCatalogInfo catalog;
  OSStatus err = FSGetCatalogInfo(&ref, kFSCatInfoVolume, &catalog, NULL, NULL, NULL);
  if (noErr == err) 
    err = WBFSCopyFolderURL(folderType, catalog.volume, createFolder, path);
  return err;
}

// MARK: Deprecated
OSStatus WBFSCopyFolderPath(OSType folderType, FSVolumeRefNum domain, bool createFolder, CFStringRef *path) {
  if (!path) return paramErr;
  
  CFURLRef url;
  OSStatus err = WBFSCopyFolderURL(folderType, domain, createFolder, &url);
  if (noErr == err) {
    *path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    if (!*path)
      err = coreFoundationUnknownErr;
    CFRelease(url);    
  }
  return err;
}

OSStatus WBFSCopyFolderPathForURL(OSType folderType, CFURLRef anURL, bool createFolder, CFStringRef *path) {
  if (!anURL || !path) return paramErr;
  
  CFURLRef url;
  OSStatus err = WBFSCopyFolderURLForURL(folderType, anURL, createFolder, &url);
  if (noErr == err) {
    *path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    if (!*path)
      err = coreFoundationUnknownErr;
    CFRelease(url);    
  }
  return err;
}

OSStatus WBFSCreateAliasFile(CFStringRef folder, CFStringRef aliasName, CFStringRef target) {
  if (!folder || !aliasName || !target) return paramErr;
  
  FSRef src;
  FSRef parent;
  OSStatus err = noErr;
  Boolean isDir = false;
  Boolean pIsDir = false;
  AliasHandle alias = NULL;
  
  err = WBFSRefCreateFromFileSystemPath(target, kFSPathMakeRefDefaultOptions, &src, &isDir);
  require_noerr(err, bail);
  
  err = FSNewAlias(NULL, &src, &alias);
  require_noerr(err, bail);
  
  err = WBFSRefCreateFromFileSystemPath(folder, kFSPathMakeRefDefaultOptions, &parent, &pIsDir);
  require_noerr(err, bail);
  
  if (!pIsDir)
    return errFSNotAFolder;
  
  FSRef rsrc;
  HFSUniStr255 rsrcStr;
  /* Get rsrc fork name */
  err = FSGetResourceForkName(&rsrcStr);
  require_noerr(err, bail);
  
  {
    /* Get destination file name */
    HFSUniStr255 aliasStr;
    err = FSGetHFSUniStrFromString(aliasName, &aliasStr);
    require_noerr(err, bail);
    
    /* set type, creator, and flags */
    FSCatalogInfo info;
    memset(&info, 0, sizeof(info));
    FileInfo *finfo = (FileInfo *)info.finderInfo;
    finfo->fileType = kContainerFolderAliasType;
    finfo->fileCreator = 'MACS';
    finfo->finderFlags = kIsAlias;
    
    err = FSCreateResourceFile(&parent, aliasStr.length, aliasStr.unicode,
                               kFSCatInfoFinderInfo, &info, 
                               rsrcStr.length, rsrcStr.unicode, &rsrc, NULL);
    require_noerr(err, bail);
  }
  
  /* rsrc point on the new resource file, we have to fill it */
  ResFileRefNum rsrcRef = 0;
  err = FSOpenResourceFile(&rsrc, rsrcStr.length, rsrcStr.unicode, fsWrPerm, &rsrcRef);
  require_noerr(err, delete);
  
  AddResource((Handle)alias, 'alis', 0, "\p");
  err = ResError();
  require_noerr(err, close);
  /* Resource Manager will free alias when needed */
  alias = NULL;
  
close:
    CloseResFile(rsrcRef);

delete:
    if (noErr != err)
      FSDeleteFork(&rsrc, rsrcStr.length, rsrcStr.unicode);
    
bail:
    if (alias)
      DisposeHandle((Handle)alias);
  
    return err;
}

OSStatus WBFSCreateTemporaryURLForURL(CFURLRef anURL, CFURLRef *result) {
  CFURLRef folder;
  OSStatus err = WBFSCopyFolderURLForURL(kTemporaryFolderType, anURL, true, &folder);
  if (noErr != err) return err;
  
  char stack[PATH_MAX];
  char *buffer = stack;
  if (!CFURLGetFileSystemRepresentation(folder, true, (UInt8 *)buffer, PATH_MAX - 25)) {
    buffer = NULL;
    // avoid stupid 1024 file path length limitation
    CFStringRef str = CFURLCopyFileSystemPath(folder, kCFURLPOSIXPathStyle);
    if (str) {
      CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(str);
      buffer = malloc(length + 25);
      if (!CFStringGetFileSystemRepresentation(str, buffer, length)) {
        free(buffer);
        buffer = NULL;
      }
      CFRelease(str);
    }
  }
  CFRelease(folder);
  
  if (!buffer)
    return coreFoundationUnknownErr;
  
  char filename[32];
  snprintf(filename, 32, "/%.14s.XXXXXXXX", getprogname());
  strncat(buffer, filename, 24);

  // by using mkstemp, we avoid a race condition
  int fd = mkstemp(buffer);
  if (fd < 0)
    return kPOSIXErrorBase + errno;
  close(fd);
  
  *result = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)buffer, strlen(buffer), false);
  if (!*result)
    err = coreFoundationUnknownErr;
  
  if (buffer != stack)
    free(buffer);
  
  return err;
}


CFStringRef WBFSCopyTemporaryFilePath(FSVolumeRefNum domain, CFStringRef prefix, CFStringRef ext, CFURLPathStyle pathType) {
  if (ext && CFStringGetLength(ext) > 16) {
    debug_string("\"ext\" length must be less than 16 characters");
    return nil;
  }
  CFStringRef temp = nil;
  FSRef folder;
  OSErr err = FSFindFolder(domain,
                           kTemporaryFolderType,
                           kCreateFolder,
                           &folder);
  if (noErr == err) {
    HFSUniStr255 name;
    name.length = 0;
    if (!prefix) {
      const char *prog = getprogname();
      if (!prog || !(prefix = CFStringCreateWithCString(kCFAllocatorDefault, prog, CFStringGetSystemEncoding()))) {
        prefix = CFSTR("tmp");
      }
    } else {
      CFRetain(prefix);
    }
    if (CFStringGetLength(prefix) < 240) {
      name.length = CFStringGetLength(prefix);
      CFStringGetCharacters(prefix, CFRangeMake(0, name.length), name.unicode);
      name.unicode[name.length] = '_';
      name.length++;
    }
    CFRelease(prefix);
    
    /* Create Unique file name */
    FSRef fileRef;
    char suffix[16];
    NSUInteger uid = 0;
    CFIndex suffixLen = 0;
    /* Get extension */
    UniChar extension[16];
    CFIndex extLen = (ext) ? CFStringGetLength(ext) : 0;
    CFStringGetCharacters(ext, CFRangeMake(0, extLen), extension);
    
    do {
      sprintf(suffix, "%lu", (long)uid++);
      for (NSUInteger idx = 0; idx < strlen(suffix); idx++) {
        name.unicode[name.length + idx] = suffix[idx];
      }
      suffixLen = strlen(suffix);
      /* Append extension */
      if (extLen > 0) {
        /* Append "." */
        name.unicode[name.length + suffixLen] = '.';
        suffixLen += 1;
        /* Append ext */
        for (CFIndex idx = 0; idx < extLen; idx++) {
          name.unicode[name.length + suffixLen + idx] = extension[idx];
        }
        suffixLen += extLen; /* Suffix + "." + ext */
      }
    } while (fnfErr != FSMakeFSRefUnicode(&folder, name.length + suffixLen, name.unicode, kTextEncodingUnknown, &fileRef));
    /* Maybe need check if length < 255 */
    name.length += suffixLen;
    
    CFURLRef url = NULL;
    CFURLRef full = NULL;
    CFStringRef file = CFStringCreateWithCharacters(kCFAllocatorDefault, name.unicode, name.length);
    if (file) {
      url = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
      if (url) {
        full = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, url, file, NO);
        CFRelease(url);
      }
      if (full) {
        temp = CFURLCopyFileSystemPath(full, pathType);
        CFRelease(full);
      }
      CFRelease(file);
    }
  }
  return temp;
}
