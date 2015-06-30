/*
 *  NSDictionary+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (WBExtensions)

- (void)setObject:(id)anObject forKeys:(NSArray *)keys;

@end
