/*
 *  WBPlugInLoader.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
 @header WBPlugInLoader
 @abstract   (description)
 @discussion (description)
 */

#import <WonderBox/WBBase.h>

typedef NS_ENUM(NSUInteger, WBPlugInDomain) {
  kWBPlugInDomainUser = 1,
  kWBPlugInDomainLocal,
  kWBPlugInDomainNetwork,
  kWBPlugInDomainBuiltIn,
  kWBPlugInDomainUserDefined,
};

WB_EXPORT
NSString * const WBPlugInLoaderDidLoadPlugInNotification;
WB_EXPORT
NSString * const WBPlugInLoaderDidRemovePlugInNotification;

/*!
 @abstract    A generic PlugIn loader.
 @discussion  Should be subclassed.
 */
@class WBPlugInBundle;
WB_OBJC_EXPORT
@interface WBPlugInLoader : NSObject {
@private
  NSMutableArray *wb_domains;
  NSMutableDictionary *wb_plugins;
}

/*!
 @method
 @abstract   Init with kWBDefaultDomains, without subscription.
 @discussion
 @result     Returns a new PlugIn Loader.
 */
- (id)init;
- (id)initWithDomains:(WBPlugInDomain)domains, ... WB_REQUIRES_NIL_TERMINATION;

#pragma mark Paths
- (void)loadPlugIns;

// To override
/* bundle */
- (NSString *)extension;
/* Main bundle, builtInPath */
- (NSString *)buildInPath;
/*!
 @method
 @result Returns module folder name (PlugIns by default).
 */
- (NSString *)plugInFolderName;

/*!
 @method
 @discussion Name of the folder in Application Support.
 @result Returns process name by default.
 */
- (NSString *)supportFolderName;
- (NSString *)pathForDomain:(WBPlugInDomain)domain;

#pragma mark PlugIns
- (NSArray *)plugIns;
- (NSEnumerator *)plugInEnumerator;
- (NSArray *)plugInsForDomain:(WBPlugInDomain)domain;

/* Accessing PlugIns */
- (id)plugInForClass:(Class)class;
- (id)plugInForBundle:(NSBundle *)aBundle;
- (id)plugInForIdentifier:(NSString *)anIdentifier;

- (id)loadPlugIn:(NSBundle *)aBundle;
- (id)loadPlugInAtPath:(NSString *)aPath; // call loadPlugIn:

/* Built-in PlugIns support */
- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier;
- (void)unregisterPlugIn:(NSString *)identifier;

/* Protected */
- (id)createPlugInForBundle:(NSBundle *)bundle;
- (WBPlugInBundle *)resolveConflict:(NSArray *)plugins;

@end

@interface WBPlugInBundle : NSObject {
@private
  NSBundle *wb_bundle;
  WBPlugInDomain wb_domain;
}

- (NSBundle *)bundle;
- (WBPlugInDomain)domain;

@end
