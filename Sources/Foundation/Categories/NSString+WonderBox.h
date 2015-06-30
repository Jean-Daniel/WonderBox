/*
 *  NSString+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Foundation/Foundation.h>

@interface NSString (WBStringComparaison)
- (BOOL)hasPrefixCaseInsensitive:(NSString *)aString;
- (BOOL)hasSuffixCaseInsensitive:(NSString *)aString;
/* Case insensitive + numeric */
- (NSComparisonResult)numericCompare:(NSString *)aString;
@end

#pragma mark -
@interface NSString (WBXMLEscaping)
- (NSString *)stringByEscapingEntities:(NSDictionary *)entities;
- (NSString *)stringByUnescapingEntities:(NSDictionary *)entities;
@end

#pragma mark -
@interface NSString (WBLineUtilities)
- (NSRange)rangeOfLine:(NSUInteger)line;
- (NSRange)rangeOfLine:(NSUInteger)line inRange:(NSRange)aRange;

- (NSString *)stringByTrimmingWhitespace;
- (NSString *)stringByTrimmingWhitespaceAndNewline;
@end

@interface NSString (WBUtilities)
+ (id)localizedStringWithSize:(UInt64)size unit:(NSString *)unit precision:(NSUInteger)precision;
@end
