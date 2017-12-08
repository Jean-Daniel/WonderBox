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

CF_ASSUME_NONNULL_BEGIN

__BEGIN_DECLS

#pragma mark -
#pragma mark File System C API

/*!
 @return true if both URL points to the same file.
 */
WB_EXPORT
bool WBFSCompareURLs(CFURLRef url1, CFURLRef url2);

/* Format a size and return buffer used length */
//WB_EXPORT ssize_t WBFSFormatSize(UInt64 size, CFIndex precision, const char *unit, char *buffer, size_t length);
//
//WB_EXPORT OSStatus WBFSDeleteEmptyFolderAtURL(CFURLRef anURL);

/* delete an object using the posix convention (ignore busy files), and unlock it if needed */
// WB_EXPORT OSStatus WBFSForceDeleteObjectAtURL(CFURLRef anURL);

CF_ASSUME_NONNULL_END

#if defined(__OBJC__)

#import <Foundation/Foundation.h>

@interface NSString (WBFileSystem)

// same as fileSystemRepresentation but returns nil instead of throwing an exception
- (nullable const char *)safeFileSystemRepresentation;

@end

#endif /* __OBJC__ */

__END_DECLS

#endif /* __WB_FS_FUNCTIONS_H */
