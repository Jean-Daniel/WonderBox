/*
 *  WBAlias.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBAlias.h>

@implementation WBAlias

@synthesize URL = _URL;
@synthesize data = _data;

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBAlias *copy = [[self class] allocWithZone:zone];
  copy->_URL = _URL;
  copy->_data = _data;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (_URL)
    [coder encodeObject:_URL.absoluteURL.path forKey:@"WBAliasPath"];
  if (_data)
    [coder encodeObject:_data forKey:@"WBBookmarkData"];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    NSString *path = [coder decodeObjectForKey:@"WBAliasPath"];
    if (path)
      _URL = [NSURL fileURLWithPath:path];
    _data = [coder decodeObjectForKey:@"WBBookmarkData"];
    if (!_data) {
      NSData *alias = [coder decodeObjectForKey:@"WBAliasHandle"];
      if (alias)
        _data = SPXCFDataBridgingRelease(CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, SPXNSToCFData(alias)));
    }
  }
  return self;
}

#pragma mark -
+ (instancetype)aliasWithURL:(NSURL *)anURL {
  return [[self alloc] initWithURL:anURL];
}

+ (instancetype)aliasFromBookmarkData:(NSData *)data {
  return [[self alloc] initFromBookmarkData:data];
}

#pragma mark Initializers
- (instancetype)initWithURL:(NSURL *)anURL {
  if (!anURL)
    return nil;

  if (self = [self init]) {
    _URL = anURL;
  }
  return self;
}

- (instancetype)initFromBookmarkData:(NSData *)data {
  if (!data)
    return nil;

  if (self = [super init]) {
    _data = [data copy];
  }
  return self;
}

#pragma mark -
- (NSURL *)URL {
  if (!_URL && _data) {
    BOOL isStale = NO;
    _URL = [[NSURL alloc] initByResolvingBookmarkData:_data options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting relativeToURL:nil bookmarkDataIsStale:&isStale error:NULL];
    if (_URL && isStale)
      _data = [_URL bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
  }
  return _URL;
}

- (NSData *)data {
  if (!_data && _URL) {
    _data = [_URL bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
  }
  return _data;
}

@end

@implementation WBAlias (WBAliasHandle)

+ (instancetype)aliasFromData:(NSData *)data {
  return [[self alloc] initFromData:data];
}

+ (instancetype)aliasWithPath:(NSString *)aPath {
  return [[self alloc] initWithURL:[NSURL fileURLWithPath:aPath]];
}

- (instancetype)initFromData:(NSData *)data {
  NSParameterAssert(data && [data length] > 0);

  CFDataRef bookmark = CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, SPXNSToCFData(data));
  if (bookmark) {
    self = [self initFromBookmarkData:SPXCFToNSData(bookmark)];
    CFRelease(bookmark);
  } else {
    return nil;
  }
  return self;
}

- (instancetype)initWithPath:(NSString *)aPath {
  return [self initWithURL:[NSURL fileURLWithPath:aPath]];
}

- (NSString *)path {
  return self.URL.path;
}

@end
