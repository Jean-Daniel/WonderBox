/*
 *  WBAliasedApplication.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBAliasedApplication.h>

#import <WonderBox/WBAlias.h>
#import <WonderBox/WBLSFunctions.h>

@implementation WBAliasedApplication

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  WBAliasedApplication *copy = [super copyWithZone:zone];
  copy->wb_alias = [wb_alias copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  if (wb_alias)
    [coder encodeObject:wb_alias forKey:@"WBApplicationAlias"];
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    wb_alias = [[coder decodeObjectForKey:@"WBApplicationAlias"] retain];
  }
  return self;
}

#pragma mark -
- (id)initWithAlias:(WBAlias *)anAlias {
  if (self = [super initWithPath:nil]) {
    [self setAlias:anAlias];
  }
  return self;
}

- (void)dealloc {
  [wb_alias release];
  [super dealloc];
}

#pragma mark -
- (WBAlias *)alias {
  if (!wb_alias) {
    NSString *path = [super path];
    if (path)
      wb_alias = [[WBAlias alloc] initWithPath:path];
  }
  return wb_alias;
}
- (void)setAlias:(WBAlias *)anAlias {
  [self setPath:[anAlias path]];
//  if ([super setPath:[anAlias path]]) {
//    WBSetterCopy(&wb_alias, anAlias);
//  }
}

- (NSString *)path {
  return [[self alias] path] ? : [super path];
}
- (BOOL)setPath:(NSString *)aPath {
  /* Invalidate and update alias */
  [wb_alias release];
  wb_alias = nil;

  BOOL result = [super setPath:aPath];

  if (!result) {
    /* this condition is reached when an application does not have identifier */
    /* we check if the file is really an application, and if it is the case, we save the alias */
    Boolean isApp = false;
    result = (noErr == WBLSIsApplicationAtPath((CFStringRef)aPath, &isApp) && isApp);
  }

  if (result && aPath)
    wb_alias = [[WBAlias alloc] initWithPath:aPath];

  return result;
}

- (void)setSignature:(OSType)aSignature bundleIdentifier:(NSString *)identifier {
  [super setSignature:aSignature bundleIdentifier:identifier];
  /* Invalidate alias */
  [wb_alias release];
  wb_alias = nil;
}

@end
