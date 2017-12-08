/*
 *  WBApplication.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBApplication.h>

#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBLSFunctions.h>

enum {
  kWBUndefinedSignature = kUnknownType // '????'
};

@implementation WBApplication {
@private
  NSString *wb_name;
  NSString *wb_identifier;
}

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBApplication *copy = [[[self class] allocWithZone:zone] init];
  copy->wb_name = [wb_name copyWithZone:zone];
  copy->wb_identifier = [wb_identifier copyWithZone:zone];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (wb_name) [coder encodeObject:wb_name forKey:@"WBName"];
  if (wb_identifier) [coder encodeObject:wb_identifier forKey:@"WBIdentifier"];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    wb_name = [coder decodeObjectForKey:@"WBName"];
    wb_identifier = [coder decodeObjectForKey:@"WBIdentifier"];
  }
  return self;
}

#pragma mark -
#pragma mark Convenient initializer
+ (instancetype)applicationWithURL:(NSURL *)anURL {
  return [[self alloc] initWithURL:anURL];
}

+ (instancetype)applicationWithProcessIdentifier:(pid_t)pid {
  return [[self alloc] initWithProcessIdentifier:pid];
}

+ (instancetype)applicationWithName:(NSString *)name {
  return [[self alloc] initWithName:name];
}

+ (instancetype)applicationWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier {
  return [[self alloc] initWithName:name bundleIdentifier:anIdentifier];
}


#pragma mark -
- (instancetype)initWithURL:(NSURL *)anURL {
  if (!anURL)
    return nil;

  if (self = [super init]) {
    if (![self setURL:anURL])
      return nil;
  }

  return self;
}

- (instancetype)initWithProcessIdentifier:(pid_t)pid {
  NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
  NSString *bundleId = app.bundleIdentifier;
  self = bundleId ? [self initWithName:app.localizedName bundleIdentifier:bundleId] : nil;
  return self;
}

- (id)initWithName:(NSString *)name {
  if (self = [super init]) {
    [self setName:name];
  }
  return self;
}

- (instancetype)initWithName:(NSString *)name bundleIdentifier:(NSString *)anIdentifier {
  if (self = [super init]) {
    wb_identifier = [anIdentifier copy];
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {name='%@', identifier='%@'}",
    [self class], self,
    wb_name, wb_identifier];
}

static NSString * const kInvalidIdentifier = @"org.shadowlab.__invalid__";

WB_INLINE
bool __IsValidIdentifier(id identifier) {
  return identifier && identifier != kInvalidIdentifier;
}

- (NSUInteger)hash {
  return wb_identifier.hash;
}

- (BOOL)isEqual:(id)object {
  if (self == object)
    return YES;

  if (![object isKindOfClass:[WBApplication class]])
    return NO;

  NSString *otherId = [object bundleIdentifier];
  if (wb_identifier) {
    if (!otherId || ![wb_identifier isEqualToString:otherId])
      return NO;
  } else if (otherId) {
    return NO;
  }

  return YES;
}

#pragma mark -
- (NSString *)name {
  if (!wb_name) {
    NSURL *path = self.URL;
    if (path) {
      NSString *name;
      if ([path getResourceValue:&name forKey:NSURLLocalizedNameKey error:NULL]) {
        wb_name = [name copy];
      }
    }
  }
  return wb_name;
}

- (void)setName:(NSString *)newName {
  SPXSetterCopy(wb_name, newName);
}

- (NSString *)bundleIdentifier {
  if (!wb_identifier) {
    NSURL *path = [self URL];
    if (path) {
      wb_identifier = SPXCFStringBridgingRelease(WBLSCopyBundleIdentifierForURL(SPXNSToCFURL(path)));
    }
    if (!wb_identifier)
      wb_identifier = kInvalidIdentifier;
  }
  return (__IsValidIdentifier(wb_identifier)) ? wb_identifier : nil;
}
- (void)setBundleIdentifier:(NSString *)identifier {
  SPXSetterCopy(wb_identifier, identifier);
  // FIXME: invalidate name ?
}

#pragma mark -
- (BOOL)isValid {
  return __IsValidIdentifier(wb_identifier);
}
- (NSImage *)icon {
  NSString *path = self.URL.path;
  return path ? [[NSWorkspace sharedWorkspace] iconForFile:path] : nil;
}

- (NSURL *)URL {
  if (__IsValidIdentifier(wb_identifier))
    return [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:wb_identifier];

  return nil;
}

- (BOOL)setURL:(NSURL *)anURL {
  /* Reset name */
  [self setName:nil];

  if (!anURL) {
    self.bundleIdentifier = nil;
    return YES;
  }

  Boolean isApp = false;
  if (noErr != WBLSIsApplicationAtURL(SPXNSToCFURL(anURL), &isApp) || !isApp) {
    return NO;
  }

  CFStringRef bundle = WBLSCopyBundleIdentifierForURL(SPXNSToCFURL(anURL));
  self.bundleIdentifier = SPXCFToNSString(bundle);
  SPXCFRelease(bundle);

  return [self isValid];
}

- (pid_t)processIdentifier {
  if (__IsValidIdentifier(wb_identifier))
    return [NSRunningApplication runningApplicationsWithBundleIdentifier:wb_identifier].firstObject.processIdentifier;

  return -1;
}

- (BOOL)launch {
  NSURL *url = self.URL;
  return url ? [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url options:NSWorkspaceLaunchDefault configuration:@{} error:NULL] != nil : NO;
}

- (BOOL)isFront {
  pid_t pid = self.processIdentifier;
  if (pid <= 0)
    return NO;
  pid_t front = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
  return front == pid;
}

- (BOOL)isRunning {
  return self.processIdentifier > 0;
}

@end

