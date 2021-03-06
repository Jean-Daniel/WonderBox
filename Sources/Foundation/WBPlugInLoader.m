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

NSString * const WBPlugInLoaderDidLoadPlugInNotification = @"WBPlugInLoaderDidLoadPlugIn";
NSString * const WBPlugInLoaderDidRemovePlugInNotification = @"WBPlugInLoaderDidRemovePlugIn";

@interface _WBPlugInDomain : NSObject {
@private
  NSURL *wb_url;
  WBPlugInDomain wb_domain;
  NSMutableArray *wb_plugins;
}

+ (id)domainWithName:(WBPlugInDomain)aDomain;

- (id)initWithDomainName:(WBPlugInDomain)aDomain;

@property(nonatomic, retain) NSURL *URL;

- (NSArray *)plugIns;
- (WBPlugInDomain)name;

- (void)addPlugIn:(id)aPlugin;
- (void)removePlugIn:(id)aPlugin;
- (BOOL)containsPlugIn:(id)aPlugin;

@end

@interface WBPlugInBundle ()

+ (id)plugInWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain;
- (id)initWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain;

@end

@interface WBPlugInLoader ()

- (NSArray *)findPlugInsAtURL:(NSURL *)anURL;

- (_WBPlugInDomain *)domainForPlugIn:(id)aPlugIn;
- (_WBPlugInDomain *)domainWithName:(WBPlugInDomain)aName;

- (id)loadPlugIn:(NSBundle *)aBundle domain:(WBPlugInDomain)aName;

- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier domain:(WBPlugInDomain)aDomain;

@end

@implementation WBPlugInLoader {
@private
  NSMutableArray *wb_domains;
  NSMutableDictionary *wb_plugins;
}

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
        SPXThrowException(NSInvalidArgumentException, @"domain %lu is defined twice", (long)domain);
      }
      [wb_domains addObject:[_WBPlugInDomain domainWithName:domain]];
    }
    va_end(args);
  }
  return self;
}

#pragma mark -
- (NSString *)extension {
  return @"bundle";
}

- (NSString *)plugInFolderName {
  return @"PlugIns";
}

- (NSString *)supportFolderName {
  return [NSProcessInfo processInfo].processName;
}

- (NSURL *)buildInURL {
  NSString *folder = [self plugInFolderName];
  NSURL *builtin = [[NSBundle mainBundle] builtInPlugInsURL];
  if (![folder isEqualToString:[builtin lastPathComponent]]) {
    return [[builtin URLByDeletingLastPathComponent] URLByAppendingPathComponent:folder];
  } else {
    return builtin;
  }
}

- (NSURL *)URLForDomain:(WBPlugInDomain)domain {
  NSString *base = [[self supportFolderName] stringByAppendingPathComponent:[self plugInFolderName]];
  NSFileManager *filemanager = [NSFileManager defaultManager];
  switch (domain) {
    default: return nil;
    case kWBPlugInDomainUser:
      return [[filemanager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:base];
    case kWBPlugInDomainLocal:
      return [[filemanager URLForDirectory:NSApplicationSupportDirectory inDomain:NSLocalDomainMask appropriateForURL:nil create:NO error:NULL] URLByAppendingPathComponent:base];
    case kWBPlugInDomainBuiltIn:
      return [self buildInURL];
  }
}

- (_WBPlugInDomain *)domainForPlugIn:(id)aPlugin {
  for (NSUInteger idx = 0, count = [wb_domains count]; idx < count; idx++) {
    _WBPlugInDomain *domain = wb_domains[idx];
    if ([domain containsPlugIn:aPlugin])
      return domain;
  }
  return nil;
}
- (_WBPlugInDomain *)domainWithName:(WBPlugInDomain)aName {
  for (NSUInteger idx = 0, count = [wb_domains count]; idx < count; idx++) {
    _WBPlugInDomain *domain = wb_domains[idx];
    if ([domain name] == aName)
      return domain;
  }
  return nil;
}

#pragma mark -
- (NSArray *)plugIns {
  return [wb_plugins allValues];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
  return [wb_plugins countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSArray *)plugInsForDomain:(WBPlugInDomain)domain {
  return [[self domainWithName:domain] plugIns];
}

- (id)plugInForClass:(Class)class {
  return [self plugInForBundle:[NSBundle bundleForClass:class]];
}

- (id)plugInForBundle:(NSBundle *)aBundle {
  NSString *key = [aBundle bundleIdentifier];
  return key ? wb_plugins[key] : nil;
}

- (id)plugInForIdentifier:(NSString *)anIdentifier {
  return anIdentifier ? wb_plugins[anIdentifier] : nil;
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
    _WBPlugInDomain *domain = wb_domains[idx];
    domain.URL = [self URLForDomain:[domain name]];
    NSArray *plugins = [self findPlugInsAtURL:domain.URL];
    if (plugins) {
      for (NSUInteger idx2 = 0; idx2 < [plugins count]; idx2++) {
        NSBundle *bundle = plugins[idx2];
        NSString *uid = [bundle bundleIdentifier];
        WBPlugInBundle *entry = [WBPlugInBundle plugInWithBundle:bundle domain:[domain name]];
        if (bundles[uid] != nil) {
          // conflict
          NSMutableArray *cfl = conflicts[uid];
          if (!cfl) {
            cfl = [NSMutableArray array];
            [conflicts setObject:cfl forKey:uid];
            // add previous entry
            [cfl addObject:bundles[uid]];
          }
          // add conflict entry
          [cfl addObject:entry];
        } else {
          bundles[uid] = entry;
        }
      }
    }
  }

  NSString *uid;
  NSEnumerator *uids = [conflicts keyEnumerator];
  while (uid = [uids nextObject]) {
    WBPlugInBundle *entry = [self resolveConflict:conflicts[uid]];
    if (entry)
      bundles[uid] = entry;
  }

  WBPlugInBundle *dict;
  NSEnumerator *entries = [bundles objectEnumerator];
  while (dict = [entries nextObject]) {
    [self loadPlugIn:[dict bundle] domain:[dict domain]];
  }
}

/* Discover new PlugIns */
- (NSArray *)findPlugInsAtURL:(NSURL *)anURL {
  NSParameterAssert(anURL);
  NSString *ext = [self extension];
  NSMutableArray *plugins = [NSMutableArray array];

  NSError *error;
  NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[anURL URLByResolvingSymlinksInPath]
                                                includingPropertiesForKeys:@[]
                                                                   options:0
                                                                     error:&error];
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
  spx_log("plugins have the same identifier: %@", plugins);
  return nil;
}

- (NSDictionary *)createPlugInForBundle:(NSBundle *)bundle {
  NSDictionary *plug = nil;
  Class principalClass = bundle.principalClass;
  if (principalClass) {
    plug = @{ @"Class": principalClass,
              @"Path": bundle.bundlePath };
  }
  return plug;
}

- (id)loadPlugIn:(NSBundle *)aBundle {
  NSString *path = [aBundle bundlePath];

  for (NSUInteger idx = 0; idx < [wb_domains count]; idx++) {
    _WBPlugInDomain *domain = wb_domains[idx];
    if (domain.URL && [path hasPrefix:[domain.URL path]]) {
      return [self loadPlugIn:aBundle domain:[domain name]];
    }
  }
  /* not a registred domain */
  if (![self domainWithName:kWBPlugInDomainUserDefined])
    [wb_domains addObject:[_WBPlugInDomain domainWithName:kWBPlugInDomainUserDefined]];
  return [self loadPlugIn:aBundle domain:kWBPlugInDomainUserDefined];
}

- (id)loadPlugInAtURL:(NSURL *)anURL {
  NSBundle *bundle = [NSBundle bundleWithURL:anURL];
  return bundle ? [self loadPlugIn:bundle] : nil;
}

- (id)loadPlugIn:(NSBundle *)aBundle domain:(WBPlugInDomain)aName {
  id plugin = nil;
  @try {
    if (!wb_plugins[aBundle.bundleIdentifier]) {
      /* New bundle found */
      plugin = [self createPlugInForBundle:aBundle];
      if (plugin)
        [self registerPlugIn:plugin withIdentifier:[aBundle bundleIdentifier] domain:aName];
    } else {
      spx_log("PlugIn already loaded: %@", [aBundle bundleIdentifier]);
    }
  } @catch (NSException *exception) {
    spx_log_exception(exception);
  }
  return plugin;
}

/* Load PlugIns */
- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier domain:(WBPlugInDomain)aDomain {
  NSAssert(!wb_plugins[identifier], @"plugin already loaded");

  spx_debug("Register plugin: %@", plugin);
  wb_plugins[identifier] = plugin;
  NSAssert([self domainWithName:aDomain], @"domain does not exists");
  [[self domainWithName:aDomain] addPlugIn:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:WBPlugInLoaderDidLoadPlugInNotification object:plugin];
}


#pragma mark Built-in PlugIns
- (void)registerPlugIn:(id)plugin withIdentifier:(NSString *)identifier {
  if (wb_plugins[identifier])
    SPXThrowException(NSInvalidArgumentException, @"PlugIn %@ already loaded", identifier);

  [self registerPlugIn:plugin withIdentifier:identifier domain:kWBPlugInDomainBuiltIn];
}

- (void)unregisterPlugIn:(NSString *)identifier {
  id plugin = wb_plugins[identifier];
  if (!plugin)
    SPXThrowException(NSInvalidArgumentException, @"plugin %@ not found", identifier);

  [wb_plugins removeObjectForKey:identifier];
  NSAssert([self domainForPlugIn:plugin], @"domain not found for plugin %@", plugin);
  [[self domainForPlugIn:plugin] removePlugIn:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:WBPlugInLoaderDidRemovePlugInNotification object:plugin];
}

@end

#pragma mark -
@implementation _WBPlugInDomain

+ (id)domainWithName:(WBPlugInDomain)aDomain {
  return [[self alloc] initWithDomainName:aDomain];
}

- (id)initWithDomainName:(WBPlugInDomain)aDomain {
  if (self = [self init]) {
    wb_domain = aDomain;
    wb_plugins = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark -
- (NSURL *)URL {
  return wb_url;
}
- (void)setURL:(NSURL *)anURL {
  SPXSetterRetain(wb_url, [anURL URLByStandardizingPath]);
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

@implementation WBPlugInLoader (Deprecated)

- (NSString *)buildInPath {
  return [[self buildInURL] path];
}

- (NSString *)pathForDomain:(WBPlugInDomain)domain {
  return [[self URLForDomain:domain] path];
}

- (id)loadPlugInAtPath:(NSString *)aPath {
  NSBundle *bundle = [NSBundle bundleWithPath:aPath];
  return bundle ? [self loadPlugIn:bundle] : nil;
}

@end

#pragma mark -
@implementation WBPlugInBundle

+ (id)plugInWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain {
  return [[self alloc] initWithBundle:aBundle domain:aDomain];
}

- (id)initWithBundle:(NSBundle *)aBundle domain:(WBPlugInDomain)aDomain {
  if (self = [super init]) {
    wb_domain = aDomain;
    wb_bundle = aBundle;
  }
  return self;
}

- (NSBundle *)bundle {
  return wb_bundle;
}
- (WBPlugInDomain)domain {
  return wb_domain;
}

@end
