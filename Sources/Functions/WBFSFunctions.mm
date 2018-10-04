/*
 *  WBFSFunctions.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBFSFunctions.h>

#include <sys/stat.h>

// MARK: File System
@implementation NSString (WBFileSystem)

- (nullable const char *)safeFileSystemRepresentation {
  const char *fsrep = NULL;
  @try {
    fsrep = [self fileSystemRepresentation];
  } @catch (NSException *exception) {
    spx_log_exception(exception);
  }
  return fsrep;
}

@end

bool WBFSCompareURLs(CFURLRef url1, CFURLRef url2) {
  if (!url1)
    return !url2;
  if (!url2)
    return false;

  CFTypeRef ptr;
  if (!CFURLCopyResourcePropertyForKey(url1, kCFURLFileResourceIdentifierKey, &ptr, nullptr))
    return false;
  spx::unique_cfptr<CFTypeRef> fsref1(ptr);

  if (!CFURLCopyResourcePropertyForKey(url2, kCFURLFileResourceIdentifierKey, &ptr, nullptr))
    return false;
  spx::unique_cfptr<CFTypeRef> fsref2(ptr);

  return CFEqual(fsref1.get(), fsref2.get());
}

// #pragma mark Misc
//ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length) {
//  if (!unit || !buffer) return paramErr;
//
//  if (size < ((UInt64)1 << 10))
//    return snprintf(buffer, length, "%llu %s", size, unit);
//
//  /* Kilo */
//  if (size < ((UInt64)1 << 20))
//    return snprintf(buffer, length, "%.*f K%s", (int)precision, (double)size / ((UInt64)1 << 10), unit);
//  /* Mega */
//  if (size < ((UInt64)1 << 30))
//    return snprintf(buffer, length, "%.*f M%s", (int)precision, (double)size / ((UInt64)1 << 20), unit);
//  /* Giga */
//  if (size < ((UInt64)1 << 40))
//    return snprintf(buffer, length, "%.*f G%s", (int)precision, (double)size / ((UInt64)1 << 30), unit);
//  /* Tera */
//  if (size < ((UInt64)1 << 50))
//    return snprintf(buffer, length, "%.*f T%s", (int)precision, (double)size / ((UInt64)1 << 40), unit);
//  /* Peta */
//  if (size < ((UInt64)1 << 60))
//    return snprintf(buffer, length, "%.*f P%s", (int)precision, (double)size / ((UInt64)1 << 50), unit);
//  /* Exa */
//  return snprintf(buffer, length, "%.*f E%s", (int)precision, (double)size / ((UInt64)1 << 60), unit);
//}

//OSStatus WBFSForceDeleteObject(const FSRef *object) {
//  if (!object) return paramErr;
//
//  FSCatalogInfo info;
//  OSStatus err = FSGetCatalogInfo(object, kFSCatInfoNodeFlags, &info, NULL, NULL, NULL);
//  if (noErr == err) {
//    if (info.nodeFlags & kFSNodeLockedMask) {
//      info.nodeFlags &= ~kFSNodeLockedMask;
//      /* result can be safely ignored as the following delete operation will failed if an error occured */
//      FSSetCatalogInfo(object, kFSCatInfoNodeFlags, &info);
//    }
//    err = FSUnlinkObject(object);
//  }
//  return err;
//}

//OSStatus WBFSDeleteEmptyFolderAtURL(CFURLRef anURL) {
//  if (!anURL)
//    return paramErr;
//
//  FSRef aFolder;
//  if (!CFURLGetFSRef(anURL, &aFolder))
//    return coreFoundationUnknownErr;
//
//  Boolean isDir;
//  OSStatus err = WBFSRefIsFolder(aFolder, &isDir);
//  if (noErr == err) {
//    if (!isDir)
//      return errFSNotAFolder;
//    FSRef folder = *aFolder;
//    do {
//      FSRef parent;
//      err = FSGetCatalogInfo(&folder, kFSCatInfoNone, NULL, NULL, NULL, &parent);
//      if (noErr == err)
//        err = FSDeleteObject(&folder);
//      if (noErr == err)
//        folder = parent;
//    } while (noErr == err);
//
//    if (fBsyErr == err) // non-empty dir, not an error
//      err = noErr;
//  }
//  return err;
//}

