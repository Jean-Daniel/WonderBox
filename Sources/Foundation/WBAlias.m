/*
 *  WBAlias.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBAlias.h)
#import WBHEADER(WBFSFunctions.h)

@implementation WBAlias

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBAlias *copy = (id)NSCopyObject(self, 0, zone);
  copy->wb_path = [wb_path retain];
  
  if (wb_alias) {
    /* Copy Handler */
    copy->wb_alias = wb_alias;
    if (noErr != HandToHand((Handle *)&copy->wb_alias)) {
      [copy release];
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
    wb_path = [[coder decodeObjectForKey:@"WBAliasPath"] retain];
    NSData *data = [coder decodeObjectForKey:@"WBAliasHandle"];
    if (data)
      PtrToHand([data bytes], (Handle *)&wb_alias, [data length]);
  }
  return self;
}

#pragma mark -
- (id)initWithPath:(NSString *)path {
  if (self = [super init]) {
    [self setPath:path];
  }
  return self;
}

- (id)initWithData:(NSData *)data {
  if (self = [super init]) {
    if ([data length]) {
      // Create a new Handle with data
      PtrToHand([data bytes], (Handle *)&wb_alias, [data length]);
      [self resolve];
    }
  }
  return self;
}

- (id)initWithAliasHandle:(AliasHandle)handle {
  if (self = [super init]) {
    if (handle) {
      wb_alias = handle;
      if (noErr == HandToHand((Handle *)&wb_alias))
        [self resolve];
    }
  }
  return self;
}

+ (id)aliasWithPath:(NSString *)path {
  return [[[self alloc] initWithPath:path] autorelease];
}

+ (id)aliasWithData:(NSData *)data {
  return [[[self alloc] initWithData:data] autorelease];
}

+ (id)aliasWithAliasHandle:(AliasHandle)handle {
  return [[[self alloc] initWithAliasHandle:handle] autorelease];
}

- (void)dealloc {
  if (wb_alias) {
    DisposeHandle((Handle)wb_alias);
    wb_alias = nil;
  }
  [wb_path release];
  [super dealloc];
}

- (NSData *)data {
  id data = nil;
  if (wb_alias) {
    data = [NSData dataWithBytes:*wb_alias length:GetAliasSize(wb_alias)];
  }
  return data;
}

- (NSString *)path {
  if (wb_path && ![[NSFileManager defaultManager] fileExistsAtPath:wb_path]) {
    [self resolve];
  }
  return [[wb_path retain] autorelease];
}

- (void)setPath:(NSString *)path {
  if (wb_path != path) {
    [wb_path release];
    wb_path = nil;
    if (wb_alias) {
      DisposeHandle((Handle)wb_alias);
      wb_alias = nil;
    }
    
    FSRef target;
    if ([path getFSRef:&target]) {
      OSErr err = FSNewAlias(nil, &target, &wb_alias);
      if (err == noErr) {
        wb_path = [path copy];
      }
    }
  }
}

- (AliasHandle)aliasHandle {
  return wb_alias;
}

- (NSString *)resolve {
  if (wb_alias) {
    FSRef target;
    Boolean wasChanged;
    [wb_path release];
    wb_path = nil;
    OSStatus err = FSResolveAliasWithMountFlags (nil,
                                                 wb_alias,
                                                 &target,
                                                 &wasChanged,
                                                 kResolveAliasFileNoUI);
    if (err == noErr) {
      wb_path = [[NSString stringFromFSRef:&target] retain];
    }
  }
  return [[wb_path retain] autorelease];
}

@end
