/*
 *  WBPlugInLoader.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBPlugInLoader.h>

#import <WonderBox/WBFSFunctions.h>

NSString * const WBPlugInLoaderDidLoadPlugInNotification = @"WBPlugInLoaderDidLoadPlugIn";
NSString * const WBPlugInLoaderDidRemovePlugInNotification = @"WBPlugInLoaderDidRemovePlugIn";

@interface _WBPlugInDomain : NSObject {
@private
  NSString *wb_path;
  WBPlugInDomain wb_domain;
  NSMutableArray *wb_plugins;
}

+ (id)domainWithName:(WBPlugInDomain)aDomain;

- (id)initWithDomainName:(WBPlugInDomain)aDomain;

- (NSString *)path;
- (NSArray *)plugIns;
- (WBPlugInDomain)name;

- (void)addPlugIn:(id)aPlugin;
- (void)removePlugIn:(id)aPlugin;
- (BOOL)containsPlugIn:(id)aPlugin;

- (void)setPath:(NSString *)aPath;

@end

@interface WBPlugInBundle ()

+ (id)plugInWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain;
- (id)initWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain;

@end

@interface WBPlugInLoader ()

- (NSArray *)findPlugInsAtPath:(NSString *)folder;

- (_WBPlugInDomain *)domainForPlugIn:(id)aPlugIn;
- (_WBPlugInDomain *)domainWithName:(WBPlugInDomain)aName;

- (id)loadPlugIn:(NSBundle *)aBundle domain:(WBPlugInDomain)aName;

- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier domain:(WBPlugInDomain)aDomain;

@end

@implementation WBPlugInLoader

- (id)init {
  return [self initWithDomains:kWBPlugInDomainUser, kWBPlugInDomainLocal, kWBPlugInDomainBuiltIn, nil];
}

- (id)initWithDomains:(WBPlugInDomain)domain, ... {
  NSParameterAssert(domain != 0);
  if (self = [super init]) {

    wb_domains = [[NSMutableArray alloc] init];

    [wb_domains addObject:[_WBPlugInDomain domainWithName:domain]];
    va_list args;
    va_start(args, domain);
    while ((domain = va_arg(args, NSUInteger))) {
      if (nil != [self domainWithName:domain]) {
        [self release];
        SPXThrowException(NSInvalidArgumentException, @"domain %lu is defined twice", (long)domain);
      }
      [wb_domains addObject:[_WBPlugInDomain domainWithName:domain]];
    }
    va_end(args);
  }
  return self;
}

- (void)dealloc {
  [wb_domains release];
  [wb_plugins release];
  [super dealloc];
}

#pragma mark -
- (NSString *)extension {
  return @"bundle";
}

- (NSString *)plugInFolderName {
  return @"PlugIns";
}

- (NSString *)supportFolderName {
  return [[NSProcessInfo processInfo] processName];
}

- (NSString *)buildInPath {
  NSString *folder = [self plugInFolderName];
  NSString *builtin = [[NSBundle mainBundle] builtInPlugInsPath];
  if (![folder isEqualToString:[builtin lastPathComponent]]) {
    return [[builtin stringByDeletingLastPathComponent] stringByAppendingPathComponent:folder];
  } else {
    return builtin;
  }
}

- (NSString *)pathForDomain:(WBPlugInDomain)domain {
  NSString *base = [[self supportFolderName] stringByAppendingPathComponent:[self plugInFolderName]];
  switch (domain) {
    default: return nil;
    case kWBPlugInDomainUser:
      return [[WBFSFindFolder(kApplicationSupportFolderType, kUserDomain, false) path] stringByAppendingPathComponent:base];
    case kWBPlugInDomainLocal:
      return [[WBFSFindFolder(kApplicationSupportFolderType, kLocalDomain, false) path] stringByAppendingPathComponent:base];
    case kWBPlugInDomainNetwork:
      return [[WBFSFindFolder(kApplicationSupportFolderType, kNetworkDomain, false) path] stringByAppendingPathComponent:base];
    case kWBPlugInDomainBuiltIn:
      return [self buildInPath];
  }
}

- (_WBPlugInDomain *)domainForPlugIn:(id)aPlugin {
  for (NSUInteger idx = 0, count = [wb_domains count]; idx < count; idx++) {
    _WBPlugInDomain *domain = [wb_domains objectAtIndex:idx];
    if ([domain containsPlugIn:aPlugin])
      return domain;
  }
  return nil;
}
- (_WBPlugInDomain *)domainWithName:(WBPlugInDomain)aName {
  for (NSUInteger idx = 0, count = [wb_domains count]; idx < count; idx++) {
    _WBPlugInDomain *domain = [wb_domains objectAtIndex:idx];
    if ([domain name] == aName)
      return domain;
  }
  return nil;
}

#pragma mark -
- (NSArray *)plugIns {
  return [wb_plugins allValues];
}

- (NSEnumerator *)plugInEnumerator {
  return [wb_plugins objectEnumerator];
}
- (NSArray *)plugInsForDomain:(WBPlugInDomain)domain {
  return [[self domainWithName:domain] plugIns];
}

- (id)plugInForClass:(Class)class {
  return [self plugInForBundle:[NSBundle bundleForClass:class]];
}

- (id)plugInForBundle:(NSBundle *)aBundle {
  NSString *key = [aBundle bundleIdentifier];
  return key ? [wb_plugins objectForKey:key] : nil;
}

- (id)plugInForIdentifier:(NSString *)anIdentifier {
  return anIdentifier ? [wb_plugins objectForKey:anIdentifier] : nil;
}

#pragma mark -
#pragma mark PlugIn Loader
- (void)loadPlugIns {
  if (wb_plugins) return;
  wb_plugins = [[NSMutableDictionary alloc] init];

  /* preflight */
  NSMutableDictionary *bundles = [NSMutableDictionary dictionary];
  NSMutableDictionary *conflicts = [NSMutableDictionary dictionary];

  for (NSUInteger idx = 0; idx < [wb_domains count]; idx++) {
    _WBPlugInDomain *domain = [wb_domains objectAtIndex:idx];
    [domain setPath:[self pathForDomain:[domain name]]];
    NSArray *plugins = [self findPlugInsAtPath:[domain path]];
    if (plugins) {
      for (NSUInteger idx2 = 0; idx2 < [plugins count]; idx2++) {
        NSBundle *bundle = [plugins objectAtIndex:idx2];
        NSString *uid = [bundle bundleIdentifier];
        WBPlugInBundle *entry = [WBPlugInBundle plugInWithBundle:bundle domain:[domain name]];
        if ([bundles objectForKey:uid] != nil) {
          // conflict
          NSMutableArray *cfl = [conflicts objectForKey:uid];
          if (!cfl) {
            cfl = [NSMutableArray array];
            [conflicts setObject:cfl forKey:uid];
            // add previous entry
            [cfl addObject:[bundles objectForKey:uid]];
          }
          // add conflict entry
          [cfl addObject:entry];
        } else {
          [bundles setObject:entry forKey:uid];
        }
      }
    }
  }

  NSString *uid;
  NSEnumerator *uids = [conflicts keyEnumerator];
  while (uid = [uids nextObject]) {
    WBPlugInBundle *entry = [self resolveConflict:[conflicts objectForKey:uid]];
    if (entry)
      [bundles setObject:entry forKey:uid];
  }

  WBPlugInBundle *dict;
  NSEnumerator *entries = [bundles objectEnumerator];
  while (dict = [entries nextObject]) {
    [self loadPlugIn:[dict bundle] domain:[dict domain]];
  }
}

/* Discover new PlugIns */
- (NSArray *)findPlugInsAtPath:(NSString *)folder {
  NSParameterAssert(folder);
  NSString *ext = [self extension];
  NSMutableArray *plugins = [NSMutableArray array];

  NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:folder]
                                                includingPropertiesForKeys:nil
                                                                   options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                     error:NULL];
  for (NSURL *url in urls) {
    if ([[url pathExtension] caseInsensitiveCompare:ext] == NSOrderedSame) {
      NSBundle *plugin = [NSBundle bundleWithURL:url];
      if (plugin)
        [plugins addObject:plugin];
    }
  }

  return plugins;
}

- (WBPlugInBundle *)resolveConflict:(NSArray *)plugins {
  // use first found
  SPXLogWarning(@"plugins have the same identifier: %@", plugins);
  return nil;
}

- (id)createPlugInForBundle:(NSBundle *)bundle {
  id plug = nil;
  Class principalClass = [bundle principalClass];
  if (principalClass) {
    plug = [NSDictionary dictionaryWithObjectsAndKeys:
            principalClass, @"Class",
            [bundle bundlePath], @"Path", nil];
  }
  return plug;
}

- (id)loadPlugIn:(NSBundle *)aBundle {
  NSString *path = [aBundle bundlePath];

  for (NSUInteger idx = 0; idx < [wb_domains count]; idx++) {
    _WBPlugInDomain *domain = [wb_domains objectAtIndex:idx];
    if ([domain path] && [path hasPrefix:[domain path]]) {
      return [self loadPlugIn:aBundle domain:[domain name]];
    }
  }
  /* not a registred domain */
  if (![self domainWithName:kWBPlugInDomainUserDefined])
    [wb_domains addObject:[_WBPlugInDomain domainWithName:kWBPlugInDomainUserDefined]];
  return [self loadPlugIn:aBundle domain:kWBPlugInDomainUserDefined];
}

- (id)loadPlugInAtPath:(NSString *)aPath {
  NSBundle *bundle = [NSBundle bundleWithPath:aPath];
  return bundle ? [self loadPlugIn:bundle] : nil;
}

- (id)loadPlugIn:(NSBundle *)aBundle domain:(WBPlugInDomain)aName {
  id plugin = nil;
  @try {
    if (![wb_plugins objectForKey:[aBundle bundleIdentifier]]) {
      /* New bundle found */
      plugin = [self createPlugInForBundle:aBundle];
      if (plugin)
        [self registerPlugIn:plugin withIdentifier:[aBundle bundleIdentifier] domain:aName];
    } else {
      SPXLogWarning(@"PlugIn already loaded: %@", [aBundle bundleIdentifier]);
    }
  } @catch (NSException *exception) {
    SPXLogException(exception);
  }
  return plugin;
}

/* Load PlugIns */
- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier domain:(WBPlugInDomain)aDomain {
  NSAssert(![wb_plugins objectForKey:identifier], @"plugin already loaded");

  SPXDebug(@"Register plugin: %@", plugin);
  [wb_plugins setObject:plugin forKey:identifier];
  NSAssert([self domainWithName:aDomain], @"domain does not exists");
  [[self domainWithName:aDomain] addPlugIn:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:WBPlugInLoaderDidLoadPlugInNotification object:plugin];
}


#pragma mark Built-in PlugIns
- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier {
  if ([wb_plugins objectForKey:identifier])
    SPXThrowException(NSInvalidArgumentException, @"PlugIn %@ already loaded", identifier);

  [self registerPlugIn:plugin withIdentifier:identifier domain:kWBPlugInDomainBuiltIn];
}

- (void)unregisterPlugIn:(NSString *)identifier {
  id plugin = [wb_plugins objectForKey:identifier];
  if (!plugin)
    SPXThrowException(NSInvalidArgumentException, @"plugin %@ not found", identifier);

  [plugin retain];
  [wb_plugins removeObjectForKey:identifier];
  NSAssert([self domainForPlugIn:plugin], @"domain not found for plugin %@", plugin);
  [[self domainForPlugIn:plugin] removePlugIn:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:WBPlugInLoaderDidRemovePlugInNotification object:plugin];
  [plugin release];
}

@end

#pragma mark -
@implementation _WBPlugInDomain

+ (id)domainWithName:(WBPlugInDomain)aDomain {
  return [[[self alloc] initWithDomainName:aDomain] autorelease];
}

- (id)initWithDomainName:(WBPlugInDomain)aDomain {
  if (self = [self init]) {
    wb_domain = aDomain;
    wb_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [wb_path release];
  [wb_plugins release];
  [super dealloc];
}

#pragma mark -
- (NSString *)path {
  return wb_path;
}
- (void)setPath:(NSString *)aPath {
  SPXSetterCopy(wb_path, [aPath stringByStandardizingPath]);
}

- (WBPlugInDomain)name {
  return wb_domain;
}

- (NSArray *)plugIns {
  return wb_plugins;
}
- (void)addPlugIn:(id)aPlugin {
  [wb_plugins addObject:aPlugin];
}
- (void)removePlugIn:(id)aPlugin {
  [wb_plugins removeObjectIdenticalTo:aPlugin];
}
- (BOOL)containsPlugIn:(id)aPlugin {
  return [wb_plugins indexOfObjectIdenticalTo:aPlugin] != NSNotFound;
}

@end

#pragma mark -
@implementation WBPlugInBundle

+ (id)plugInWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain {
  return [[[self alloc] initWithBundle:aBundle domain:aDomain] autorelease];
}

- (id)initWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain {
  if (self = [super init]) {
    wb_domain = aDomain;
    wb_bundle = [aBundle retain];
  }
  return self;
}

- (void)dealloc {
  [wb_bundle release];
  [super dealloc];
}

- (NSBundle *)bundle {
  return wb_bundle;
}
- (WBPlugInDomain)domain {
  return wb_domain;
}

@end
