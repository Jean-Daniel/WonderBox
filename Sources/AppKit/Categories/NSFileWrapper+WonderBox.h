/*
 *  NSFileWrapper+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileWrapper (WBExtensions)

- (nullable id)propertyListForFilename:(NSString *)filename error:(out NSError * __autoreleasing *)outError; // NSPropertyListImmutable
- (nullable id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt error:(out NSError * __autoreleasing *)outError;

@end

NS_ASSUME_NONNULL_END
