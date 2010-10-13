/*
 *  WBApplication.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBApplication
    @abstract   (description)
    @discussion (description)
*/

#import WBHEADER(WBBase.h)

#pragma mark -

/*!
    @class    WBApplication
    @abstract Object representation of an Application. Use application signature or Bundle Identifier as identifier.
*/
WB_CLASS_EXPORT
@interface WBApplication : NSObject <NSCoding, NSCopying> {
  @private
  NSString *wb_name;
  OSType wb_signature;
  NSString *wb_identifier;
}

+ (NSArray *)runningApplication:(BOOL)onlyVisible;

+ (id)applicationWithPath:(NSString *)path;
+ (id)applicationWithProcessSerialNumber:(ProcessSerialNumber *)psn;

+ (id)applicationWithName:(NSString *)name;
+ (id)applicationWithName:(NSString *)name signature:(OSType)aSignature;
+ (id)applicationWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;

/*!
  @method
 @abstract   (brief description)
 @param      path An application path.
 @result     Returns a new WBApplication, or nil of path is invalid or if file at path is not an application.
 */
- (id)initWithPath:(NSString *)path;
- (id)initWithProcessSerialNumber:(ProcessSerialNumber *)psn;

- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name signature:(OSType)aSignature;
- (id)initWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;
- (id)initWithName:(NSString *)name signature:(OSType)aSignature bundleIdentifier:(NSString *)anIdentifier;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (OSType)signature;
- (void)setSignature:(OSType)aSignature; // invalidate bundle identifier

- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)identifier; // invalidate signature

- (void)setSignature:(OSType)aSignature bundleIdentifier:(NSString *)identifier;

/* Protected */
- (BOOL)setPath:(NSString *)aPath;

#pragma mark -
- (BOOL)isValid;
- (NSImage *)icon;
- (NSString *)path;
- (BOOL)getFSRef:(FSRef *)ref;

#pragma mark -
- (BOOL)launch;
- (BOOL)isFront;
- (BOOL)isRunning;

- (ProcessSerialNumber)process;

@end
