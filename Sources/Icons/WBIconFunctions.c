/*
 *  WBIconFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <Carbon/Carbon.h>

#include WBHEADER(WBIconFunctions.h)
#include WBHEADER(WBFSFunctions.h)
#include WBHEADER(WBFinderSuite.h)

#pragma mark Static Functions Declaration
static OSStatus WBIconFamilySetCustomIconFlagAndNotify(const FSRef *ref, Boolean flag);
static OSStatus WBIconFamilyGetFolderIconFile(const FSRef *folderRef, Boolean create, FSRef *fileRef);
static OSStatus WBIconFamilyGetVolumeIconFile(const FSRef *volumeRef, Boolean create, FSRef *fileRef);
static OSStatus WBIconFamilyAddResourceTypeAsResID(IconFamilyHandle iconFamily, OSType type, ResID resID);
static OSStatus WBIconFamilySetFileIconResources(const FSRef *fsRef, IconFamilyHandle iconFamily, Boolean compatible);

#pragma mark -
#pragma mark Miscellaneous Functions
OSStatus WBIconFamilyGetSystemIcon(OSType fourByteCode, IconFamilyHandle *icon) {
  OSStatus err;
  IconRef iconRef;

  err = GetIconRef(kOnSystemDisk, kSystemIconsCreator, fourByteCode, &iconRef);
  if (noErr == err) {
    err = IconRefToIconFamily(iconRef, kSelectorAllAvailableData, icon);
    ReleaseIconRef(iconRef);
  }
  return err;
}

#pragma mark -
#pragma mark Read Icon Family From 'icns' file
Boolean WBIconFamilyReadFromPath(CFStringRef path, IconFamilyHandle *iconFamily) {
  FSRef fileRef;
  *iconFamily = NULL;
  if (noErr == WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &fileRef, NULL)) {
    return WBIconFamilyReadFromFSRef(&fileRef, iconFamily);
  }
  return false;
}

Boolean WBIconFamilyReadFromURL(CFURLRef url, IconFamilyHandle *iconFamily) {
  FSRef fileRef;
  *iconFamily = NULL;
  if (CFURLGetFSRef(url, &fileRef)) {
    return WBIconFamilyReadFromFSRef(&fileRef, iconFamily);
  }
  return false;
}

Boolean WBIconFamilyReadFromFSRef(const FSRef *ref, IconFamilyHandle *iconFamily) {
  *iconFamily = NULL;
  if (ref) {
    return noErr == ReadIconFromFSRef(ref, iconFamily);
  }
  return false;
}

#pragma mark -
#pragma mark Read Icon Family From Misc file
Boolean WBIconFamilyGetFromPath(CFStringRef path, IconFamilyHandle *iconFamily) {
  FSRef fileRef;
  *iconFamily = NULL;
  if (noErr == WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &fileRef, NULL)) {
    return WBIconFamilyGetFromFSRef(&fileRef, iconFamily);
  }
  return false;
}

Boolean WBIconFamilyGetFromURL(CFURLRef url, IconFamilyHandle *iconFamily) {
  FSRef fileRef;
  *iconFamily = NULL;
  if (CFURLGetFSRef(url, &fileRef)) {
    return WBIconFamilyGetFromFSRef(&fileRef, iconFamily);
  }
  return false;
}

Boolean WBIconFamilyGetFromFSRef(const FSRef *ref, IconFamilyHandle *iconFamily) {
  *iconFamily = NULL;
  OSStatus err;
  SInt16 theLabel;
  IconRef iconRef;

  err = GetIconRefFromFileInfo(ref,
                               0, NULL, // Name
                               kFSCatInfoNone, NULL, // Info
                               kIconServicesNormalUsageFlag, // usage
                               &iconRef, &theLabel);
  require_noerr(err, error);

  err = IconRefToIconFamily(iconRef, kSelectorAllAvailableData, iconFamily);
  ReleaseIconRef(iconRef);
  require_noerr(err, error);
  require(NULL != *iconFamily, error);

  return true;

error:
  return false;
}

#pragma mark -
#pragma mark Write Icon Family to 'icns' file
Boolean WBIconFamilyWriteToPath(IconFamilyHandle iconFamily, CFStringRef path, CFURLPathStyle pathStyle) {
  if (NULL == iconFamily) return false;
  Boolean result = false;
  CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, pathStyle, false);
  if (url) {
    result = WBIconFamilyWriteToURL(iconFamily, url);
    CFRelease(url);
  }
  return result;
}

Boolean WBIconFamilyWriteToURL(IconFamilyHandle iconFamily, CFURLRef url) {
  Boolean result = false;
  CFDataRef iconData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)*iconFamily,
                                                   GetHandleSize((Handle)iconFamily), kCFAllocatorNull);
  if (iconData) {
    result = CFURLWriteDataAndPropertiesToResource(url, iconData, NULL, NULL);
    CFRelease(iconData);
  }
  return result;
}

OSStatus WBIconFamilyWriteToFSRef(IconFamilyHandle iconFamily, FSRef *ref) {
  OSStatus err = noErr;
  if (!ref || !iconFamily)
    err = paramErr;
  if (noErr == err) {
    CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, ref);
    if (url) {
      err = WBIconFamilyWriteToURL(iconFamily, url);
      CFRelease(url);
    }
  }
  return err;
}

#pragma mark -
#pragma mark Set File or Folder Custom Icon

Boolean WBIconFamilySetIconAtPath(IconFamilyHandle iconFamily, CFStringRef path, Boolean compatible) {
  FSRef ref;
  if (noErr == WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &ref, NULL)) {
    return WBIconFamilySetIcon(iconFamily, &ref, compatible);
  }
  return false;
}

Boolean WBIconFamilySetIconAtURL(IconFamilyHandle iconFamily, CFURLRef url, Boolean compatible) {
  FSRef ref;
  if (CFURLGetFSRef(url, &ref)) {
    return WBIconFamilySetIcon(iconFamily, &ref, compatible);
  }
  return false;
}

Boolean WBIconFamilySetIcon(IconFamilyHandle iconFamily, const FSRef *ref, Boolean compatible) {
  Boolean isFolder;
  if ((ref != NULL) && (iconFamily != NULL) && (noErr == WBFSRefIsFolder(ref, &isFolder))) {
    return isFolder ? WBIconFamilySetFolderIcon(ref, iconFamily, compatible) : WBIconFamilySetFileIcon(ref, iconFamily, compatible);
  }
  return false;
}

Boolean WBIconFamilySetFileIcon(const FSRef *fsRef, IconFamilyHandle iconFamily, Boolean compatible) {
  if (noErr != WBIconFamilySetFileIconResources(fsRef, iconFamily, compatible)) {
    return false;
  }

  return noErr == WBIconFamilySetCustomIconFlagAndNotify(fsRef, true);
}

Boolean WBIconFamilySetFolderIcon(const FSRef *folderRef, IconFamilyHandle iconFamily, Boolean compatible) {
  OSStatus err;
  FSRef iconFileRef;
  FSCatalogInfo catInfo;
  FileInfo *finderInfo = (FileInfo *)catInfo.finderInfo;

  err = WBIconFamilyGetFolderIconFile(folderRef, true, &iconFileRef);
  require_noerr(err, error);

  require_noerr(WBIconFamilySetFileIconResources(&iconFileRef, iconFamily, compatible), error);

  // Make folder icon file invisible
  // Get an FSRef for the target file, and an FSRef for its parent directory that we can use in the FNNotify() call below.
  err = FSGetCatalogInfo(&iconFileRef, kFSCatInfoFinderInfo, &catInfo, NULL, NULL, NULL);
  require_noerr(err, error);

  // Get the file's type and creator codes.
  finderInfo->finderFlags = (finderInfo->finderFlags | kIsInvisible ) & ~kHasBeenInited;
  // And write info back
  err = FSSetCatalogInfo(&iconFileRef, kFSCatInfoFinderInfo, &catInfo);
  require_noerr(err, error);

  err = WBIconFamilySetCustomIconFlagAndNotify(folderRef, true);
  require_noerr(err, error);

  Boolean isRoot;
  if (noErr == WBFSRefIsRootDirectory(folderRef, &isRoot) && isRoot) {
    FSRef vIconRef;
    err = WBIconFamilyGetVolumeIconFile(folderRef, true, &vIconRef);
    require_noerr(err, error);

    err = WBIconFamilyWriteToFSRef(iconFamily, &vIconRef);
    require_noerr(err, error);

    //After writing, Ref change.
    err = WBIconFamilyGetVolumeIconFile(folderRef, false, &vIconRef);
    require_noerr(err, error);

    err = FSGetCatalogInfo(&vIconRef, kFSCatInfoFinderInfo, &catInfo, NULL, NULL, NULL);
    require_noerr(err, error);

    // Get the file's type and creator codes.
    finderInfo->finderFlags = (finderInfo->finderFlags | kIsInvisible ) & ~kHasBeenInited;
    // And write info back
    err = FSSetCatalogInfo(&vIconRef, kFSCatInfoFinderInfo, &catInfo);
    require_noerr(err, error);
  }

  return true;

error:
    return false;
}

#pragma mark -
#pragma mark Remove File or Folder Custom Icon.
Boolean WBIconFamilyRemoveIconAtPath(CFStringRef path) {
  FSRef ref;
  if (noErr == WBFSRefCreateFromFileSystemPath(path, kFSPathMakeRefDoNotFollowLeafSymlink, &ref, NULL)) {
    return WBIconFamilyRemoveIcon(&ref);
  }
  return false;
}

Boolean WBIconFamilyRemoveIconAtURL(CFURLRef url) {
  FSRef ref;
  if (CFURLGetFSRef(url, &ref)) {
    return WBIconFamilyRemoveIcon(&ref);
  }
  return false;
}

Boolean WBIconFamilyRemoveIcon(const FSRef *ref) {
  Boolean isFolder;
  if ((ref != NULL) && (noErr == WBFSRefIsFolder(ref, &isFolder))) {
    return isFolder ? WBIconFamilyRemoveFolderIcon(ref) : WBIconFamilyRemoveFileIcon(ref);
  }
  return false;
}

Boolean WBIconFamilyRemoveFileIcon(const FSRef *ref) {
  OSStatus err;
  require_noerr(WBIconFamilySetFileIconResources(ref, NULL, false), error); /* Delete Icon Rsrc */

  err = WBIconFamilySetCustomIconFlagAndNotify(ref, false);
  require_noerr(err, error);

  return true;

error:
  return false;
}

Boolean WBIconFamilyRemoveFolderIcon(const FSRef *folderRef) {
  OSStatus err;
  FSRef iconRef;
  err = WBIconFamilyGetFolderIconFile(folderRef, false, &iconRef);
  if (noErr == err) { // If file exists
    err = FSDeleteObject(&iconRef);
  } else if (fnfErr == err) {
    err = noErr;
  }
  require_noerr(err, error);

  Boolean isRoot;
  if (noErr == WBFSRefIsRootDirectory(folderRef, &isRoot) && isRoot) {
    FSRef vIconRef;
    err = WBIconFamilyGetVolumeIconFile(folderRef, false, &vIconRef);
    if (noErr == err) {
      err = FSDeleteObject(&vIconRef);
    } else if (fnfErr == err) {
      err = noErr;
    }
    require_noerr(err, error);
  }

  err = WBIconFamilySetCustomIconFlagAndNotify(folderRef, false);
  require_noerr(err, error);
  return true;

error:
    return false;
}

#pragma mark -
#pragma mark Static Functions Definition
static
OSStatus WBIconFamilySetCustomIconFlagAndNotify(const FSRef *ref, Boolean flag) {
  OSStatus err;
  FSRef parentRef;
  Boolean isFolder = false;
  FileInfo *fileInfo;
  FolderInfo *folderInfo;
  FSCatalogInfo catalogInfo;

  err = FSGetCatalogInfo(ref, kFSCatInfoFinderInfo | kFSCatInfoNodeFlags, &catalogInfo, NULL, NULL, &parentRef);
  if (noErr == err) {
    isFolder = (catalogInfo.nodeFlags & kFSNodeIsDirectoryMask) != 0;

    if (isFolder) {
      folderInfo = (FolderInfo *)catalogInfo.finderInfo;
      folderInfo->finderFlags = (flag) ? folderInfo->finderFlags | kHasCustomIcon : folderInfo->finderFlags & ~kHasCustomIcon;
      folderInfo->finderFlags &= ~kHasBeenInited;
    } else {
      fileInfo = (FileInfo *)catalogInfo.finderInfo;
      fileInfo->finderFlags = (flag) ? fileInfo->finderFlags | kHasCustomIcon : fileInfo->finderFlags & ~kHasCustomIcon;
      fileInfo->finderFlags &= ~kHasBeenInited;
    }
    err = FSSetCatalogInfo(ref, kFSCatInfoFinderInfo, &catalogInfo);
  }

  if (noErr == err) {
    if (isFolder) {
      FNNotify(ref, kFNDirectoryModifiedMessage, kNilOptions);
    }
    WBAEFinderSyncFSRef(ref);
  }

  return err;
}

static
OSStatus _WBIconFamilyGetCustomIconFile(const FSRef *folderRef, CFStringRef filename, Boolean create, FSRef *fileRef) {
  OSStatus err;
  Boolean isDir;
  UniChar iconrNameBuf[32];

  CFIndex nameLength = CFStringGetLength(filename);
  if (nameLength > 32) {
    return paramErr;
  }

  if (noErr != WBFSRefIsFolder(folderRef, &isDir) || !isDir) {
    return false;
  }

  CFStringGetCharacters (filename, CFRangeMake(0, nameLength), iconrNameBuf);

  err = FSMakeFSRefUnicode(folderRef,
                           nameLength, iconrNameBuf,
                           kTextEncodingUnknown, fileRef);

  if (fnfErr == err && create) { // If file doesn't exists and need create.
    err = FSCreateFileUnicode(folderRef,
                              nameLength, iconrNameBuf,
                              kFSCatInfoNone, NULL,
                              fileRef, NULL);
  }
  return err;
}

static
OSStatus WBIconFamilyGetFolderIconFile(const FSRef *folderRef, Boolean create, FSRef *fileRef) {
  return _WBIconFamilyGetCustomIconFile(folderRef, CFSTR("Icon\r"), create, fileRef);
}

static
OSStatus WBIconFamilyGetVolumeIconFile(const FSRef *volumeRef, Boolean create, FSRef *fileRef) {
  return _WBIconFamilyGetCustomIconFile(volumeRef, CFSTR(".VolumeIcon.icns"), create, fileRef);
}

static
OSStatus WBIconFamilySetFileIconResources(const FSRef *fsRef, IconFamilyHandle iconFamily, Boolean compatible) {
  OSStatus err = noErr;
  Boolean isFolder;
  HFSUniStr255 rsrcName;
  ResFileRefNum rsrcFile = -1;
  IconFamilyHandle iconFamilyCopy, existingIconFamily;

  if (!fsRef || (noErr != WBFSRefIsFolder(fsRef, &isFolder)) || isFolder) {
    return paramErr;
  }

  FSGetResourceForkName(&rsrcName);
  /* No need to create rsrc if we want just to remove icon */
  if (iconFamily) {
    // Make sure the file has a resource fork that we can open.  (Although
    // this sounds like it would clobber an existing resource fork, the Carbon
    // Resource Manager docs for this function say that's not the case.  If
    // the file already has a resource fork, we receive a result code of
    // dupFNErr, which is not really an error per se, but just a notification
    // to us that creating a new resource fork for the file was not necessary.)
    err = FSCreateResourceFork(fsRef, rsrcName.length, rsrcName.unicode, 0);
    if (errFSForkExists == err)
      err = noErr;
  }

  if (noErr == err) {
    // Open the file's resource fork.
    err = FSOpenResourceFile(fsRef,
                             rsrcName.length, rsrcName.unicode,
                             fsRdWrPerm, &rsrcFile);
  }
  if ((err == resNotFound || err == resFNotFound) && (NULL == iconFamily)) {
    return noErr;
  } else {
    require_noerr(err, error);
  }

  // Remove the file's existing kCustomIconResource of type kIconFamilyType
  // (if any).
  existingIconFamily = (IconFamilyHandle)GetResource(kIconFamilyType, kCustomIconResource);
  if(existingIconFamily) {
    RemoveResource((Handle)existingIconFamily);
    err = ResError();
  }
  require_noerr(err, closeFile);

  if (iconFamily) {
    // Make a copy of the icon family data to pass to AddResource().
    // (AddResource() takes ownership of the handle we pass in; after the
    // CloseResFile() call its master pointer will be set to 0xffffffff.
    // We want to keep the icon family data, so we make a copy.)
    // HandToHand() returns the handle of the copy in hIconFamily.
    iconFamilyCopy = iconFamily;
    err = HandToHand((Handle *)&iconFamilyCopy);
    require_noerr(err, closeFile);

    // Now add our icon family as the file's new custom icon.
    AddResource((Handle)iconFamilyCopy, kIconFamilyType, kCustomIconResource, "\p");
    err = ResError();
    require_noerr(err, closeFile);

    if (compatible) {
      WBIconFamilyAddResourceTypeAsResID(iconFamily, kLarge8BitData, kCustomIconResource);
      WBIconFamilyAddResourceTypeAsResID(iconFamily, kLarge1BitMask, kCustomIconResource);
      WBIconFamilyAddResourceTypeAsResID(iconFamily, kSmall8BitData, kCustomIconResource);
      WBIconFamilyAddResourceTypeAsResID(iconFamily, kSmall1BitMask, kCustomIconResource);
    }
  }

  // Close the file's resource fork, flushing the resource map and new icon
  // data out to disk.
  CloseResFile(rsrcFile);
  err = ResError();

  return err;

closeFile:
    CloseResFile(rsrcFile);
error:
    return err;
}

static OSStatus WBIconFamilyAddResourceTypeAsResID(IconFamilyHandle iconFamily, OSType type, ResID resID) {
  Handle hIconRes = NewHandle(0);
  OSStatus err;
  err = GetIconFamilyData(iconFamily, type, hIconRes);
  if(err == noErr && GetHandleSize(hIconRes) > 0) {
    AddResource(hIconRes, type, resID, "\p");
    err = ResError();
  }
  return err;
}

bool WBIsIconVariantType(OSType type) {
  switch (type) {
    case kTileIconVariant:
    case kRolloverIconVariant:
    case kDropIconVariant:
    case kOpenIconVariant:
    case kOpenDropIconVariant:
      return true;
  }
  return false;
}
