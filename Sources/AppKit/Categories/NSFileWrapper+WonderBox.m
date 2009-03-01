/*
 *  NSFileWrapper+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSFileWrapper+WonderBox.h)

@implementation NSFileWrapper (WBExtensions)

- (id)propertyListForFilename:(NSString *)filename {
  return [self propertyListForFilename:filename mutabilityOption:NSPropertyListImmutable];
}

- (id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt {
  NSData *data = [[[self fileWrappers] objectForKey:filename] regularFileContents];
  if (data) {
    return [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
  }
  return nil;
}

@end
