/*
 *  NSFileWrapper+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSFileWrapper+WonderBox.h>

@implementation NSFileWrapper (WBExtensions)

- (nullable id)propertyListForFilename:(NSString *)filename error:(out NSError * __autoreleasing *)outError {
  return [self propertyListForFilename:filename mutabilityOption:NSPropertyListImmutable error:outError];
}

- (nullable id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt error:(out __autoreleasing NSError **)outError {
  NSData *data = [self.fileWrappers[filename] regularFileContents];
  if (data)
    return [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:outError];
  return nil;
}

@end
