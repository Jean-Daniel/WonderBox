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

#import <Cocoa/Cocoa.h>

#pragma mark -

/*!
    @abstract Object representation of an Application. Use application signature or Bundle Identifier as identifier.
*/
WB_OBJC_EXPORT
@interface WBApplication : NSObject <NSCoding, NSCopying>

+ (instancetype)applicationWithURL:(NSURL *)url;
+ (instancetype)applicationWithProcessIdentifier:(pid_t)pid;

+ (instancetype)applicationWithName:(NSString *)name;
+ (instancetype)applicationWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;

/*!
  @method
 @abstract   (brief description)
 @param      anURL An application path.
 @result     Returns a new WBApplication, or nil of path is invalid or if file at path is not an application.
 */
- (instancetype)initWithURL:(NSURL *)anURL;
- (instancetype)initWithProcessIdentifier:(pid_t)pid;

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier;

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *bundleIdentifier;

/* Protected */
- (BOOL)setURL:(NSURL *)anURL;

#pragma mark -
- (NSURL *)URL;
- (BOOL)isValid;
- (NSImage *)icon;

#pragma mark -
- (BOOL)launch;
- (BOOL)isFront;
- (BOOL)isRunning;

- (pid_t)processIdentifier;

@end
