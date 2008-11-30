/*
 *  NSFileWrapper+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@interface NSFileWrapper (WBExtensions)

- (id)propertyListForFilename:(NSString *)filename; // NSPropertyListImmutable 
- (id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt;

@end
