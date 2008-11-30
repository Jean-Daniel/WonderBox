/*
 *  NSFileWrapper+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
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
