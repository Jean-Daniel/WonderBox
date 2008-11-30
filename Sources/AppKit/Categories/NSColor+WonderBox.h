/*
 *  NSColor+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

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
