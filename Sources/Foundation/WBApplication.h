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

#import <WonderBox/WBBase.h>

#pragma mark -

/*!
    @abstract Object representation of an Application. Use application signature or Bundle Identifier as identifier.
*/
WB_OBJC_EXPORT
@interface WBApplication : NSObject <NSCoding, NSCopying>

+ (NSArray *)runningApplication:(BOOL)onlyVisible;

+ (instancetype)applicationWithPath:(NSString *)path;
+ (instancetype)applicationWithProcessSerialNumber:(ProcessSerialNumber *)psn;

+ (instancetype)applicationWithName:(NSString *)name;
+ (instancetype)applicationWithName:(NSString *)name signature:(OSType)aSignature;
+ (instancetype)applicationWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;

/*!
  @method
 @abstract   (brief description)
 @param      path An application path.
 @result     Returns a new WBApplication, or nil of path is invalid or if file at path is not an application.
 */
- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithProcessSerialNumber:(ProcessSerialNumber *)psn;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name signature:(OSType)aSignature;
- (instancetype)initWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;
- (instancetype)initWithName:(NSString *)name signature:(OSType)aSignature bundleIdentifier:(NSString *)anIdentifier;

@property(nonatomic, copy) NSString *name;

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
