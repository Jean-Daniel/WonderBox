/*
 *  NSUserDefaults+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

@interface NSUserDefaults (WBUserDefaultsColor)

- (NSColor *)colorForKey:(NSString *)aKey;
- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey;

@end
