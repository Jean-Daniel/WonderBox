/*
 *  WBAlias.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBAlias.h)
#import WBHEADER(WBFSFunctions.h)

@interface WBAlias ()
- (id)initFromAliasHandleNoCopy:(AliasHandle)anHandle;
@end

@implementation WBAlias

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBAlias *copy = [[self class] allocWithZone:nil];
  copy->wb_path = [wb_path copyWithZone:zone];

  if (wb_alias) {
    /* Copy Handler */
    copy->wb_alias = wb_alias;
    if (noErr != HandToHand((Handle *)&copy->wb_alias)) {
      wb_release(copy);
      copy = nil;
    }
  }

  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (wb_path)
    [coder encodeObject:wb_path forKey:@"WBAliasPath"];
  if (wb_alias)
    [coder encodeObject:[self data] forKey:@"WBAliasHandle"];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    wb_path = wb_retain([coder decodeObjectForKey:@"WBAliasPath"]);
    NSData *data = [coder decodeObjectForKey:@"WBAliasHandle"];
    if (data && [data length] < LONG_MAX) {
      OSErr err = PtrToHand([data bytes], (Handle *)&wb_alias, (long)[data length]);
      if (noErr != err)
        WBCLogWarning("Failed to read alias data: %s", GetMacOSStatusErrorString(err));
    }
  }
  return self;
}

#pragma mark -
+ (id)aliasFromData:(NSData *)data {
  return wb_autorelease([[self alloc] initFromData:data]);
}
+ (id)aliasFromAliasHandle:(AliasHandle)handle {
  return wb_autorelease([[self alloc] initFromAliasHandle:handle]);
}

+ (id)aliasWithURL:(NSURL *)anURL {
  return wb_autorelease([[self alloc] initWithURL:anURL]);
}
+ (id)aliasWithPath:(NSString *)aPath {
  return wb_autorelease([[self alloc] initWithPath:aPath]);
}

#pragma mark Initializers
- (id)initFromAliasHandleNoCopy:(AliasHandle)anHandle {
  NSParameterAssert(anHandle);
  if (self = [self init]) {
    wb_alias = anHandle;
    [self update];
  }
  return self;
}

- (id)initFromData:(NSData *)data {
  NSParameterAssert(data && [data length] > 0);

  AliasHandle alias;
  if ([data length] < LONG_MAX && noErr == PtrToHand([data bytes], (Handle *)&alias, (long)[data length]))
    return [self initFromAliasHandleNoCopy:alias];

  wb_release(self);
  return nil;
}

- (id)initFromAliasHandle:(AliasHandle)handle {
  NSParameterAssert(handle);

  AliasHandle alias;
  if (noErr == HandToHand((Handle *)&alias))
    return [self initFromAliasHandleNoCopy:alias];

  wb_release(self);
  return nil;
}

- (id)initWithURL:(NSURL *)anURL {
  if (!anURL) {
    wb_release(self);
    return nil;
  }
  if (self = [self init]) {
    FSRef ref;
    // First, try using FSRef
    if (CFURLGetFSRef(WBNSToCFURL(anURL), &ref)) {
      AliasHandle alias;
      if (noErr == FSNewAlias(NULL, &ref, &alias))
        return [self initFromAliasHandleNoCopy:alias];
    } else if ([anURL isFileURL]) {
      // If does not works, use file path
      [self setPath:[anURL path]];
    } else {
      // unsupported URL
      wb_release(self);
      self = nil;
    }
  }
  return self;
}

- (id)initWithPath:(NSString *)aPath {
  if (!aPath) {
    wb_release(self);
    return nil;
  }
  if (self = [self init]) {
    [self setPath:aPath];
  }
  return self;
}

- (void)dealloc {
  if (wb_alias) {
    DisposeHandle((Handle)wb_alias);
    wb_alias = nil;
  }
  wb_release(wb_path);
  wb_dealloc();
}

#pragma mark -
- (NSData *)data {
  if (wb_alias) {
    Size s = GetAliasSize(wb_alias);
    if (s > 0)
      return [NSData dataWithBytes:*wb_alias length:(NSUInteger)s];
  }

  return nil;
}

- (NSURL *)URL {
  return wb_path ? [NSURL fileURLWithPath:wb_path] : nil;
}
- (void)setURL:(NSURL *)anURL {
  if (![anURL isFileURL])
    WBThrowException(NSInvalidArgumentException, @"Unsupported URL scheme: %@", [anURL scheme]);
  [self setPath:[anURL path]];
}

- (NSString *)path {
  return wb_path;
}
- (void)setPath:(NSString *)path {
  if (!path)
    WBThrowException(NSInvalidArgumentException, @"invalid path argument. MUST NOT be nil");

  if (wb_path != path) {
    wb_release(wb_path);
    wb_path = [path copy];

    if (wb_alias) {
      DisposeHandle((Handle)wb_alias);
      wb_alias = nil;
    }

    [self update];
  }
}

- (AliasHandle)aliasHandle {
  return wb_alias;
}

//- (OSStatus)setTarget:(FSRef *)target wasChanged:(BOOL *)outChanged {
//}

- (OSStatus)getTarget:(FSRef *)target wasChanged:(BOOL *)outChanged {
  NSParameterAssert(target);
  if (outChanged) *outChanged = NO;

  if (wb_alias) {
    Boolean wasChanged;
    OSStatus err = FSResolveAliasWithMountFlags(nil, wb_alias,
                                                target, &wasChanged,
                                                kResolveAliasFileNoUI);
    if (noErr == err) {
      // update path if needed
      if (wasChanged && wb_path) {
        wb_release(wb_path);
        wb_path = nil;
      }
      if (!wb_path) {
        wb_path = wb_retain([NSString stringFromFSRef:target]);
        WBAssert(wb_path, @"-[NSString stringFromFSRef:] returned nil");
        if (outChanged) *outChanged = YES;
      }
      return noErr;
    } else if (wb_path) {
      // no longer reference a valid file
      wb_release(wb_path);
      wb_path = nil;
    }
    return err;
  }

  // wb_alias is not valid. Try to use path.
  if (!wb_path)
    WBThrowException(NSInternalInconsistencyException,
                     @"Both alias and path are null");
  // try to create alias
  OSStatus err = FSPathMakeRef((const UInt8 *)[wb_path fileSystemRepresentation], target, NULL);
  if (noErr == err) {
    // return noErr even if alias creation fail to indicate that the FSRef is valid
    if (noErr == FSNewAlias(nil, target, &wb_alias) && outChanged)
      *outChanged = YES;
  }
  return err;
}

- (BOOL)update {
  FSRef target;
  BOOL updated = NO;
  [self getTarget:&target wasChanged:&updated];
  return updated;
}

@end
