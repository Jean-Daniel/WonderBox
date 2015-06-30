/*
 *  NSColor+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Cocoa/Cocoa.h>

@interface NSColor (WBColorTable)

+ (NSColor *)wbBorderColor;
+ (NSColor *)wbBackgroundColor;
+ (NSColor *)wbLightBorderColor;
+ (NSColor *)wbWindowBackgroundColor;

@end

@interface NSColor (WBHexdecimal)

+ (id)colorWithDeviceHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha;
+ (id)colorWithCalibratedHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha;

@end
