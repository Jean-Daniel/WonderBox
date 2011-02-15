/*
 *  NSString+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(NSString+WonderBox.h)

@implementation NSString (WBStringComparaison)

- (BOOL)hasPrefixCaseInsensitive:(NSString *)aString {
  NSUInteger length = [aString length];
  if (length > [self length])
    return NO;
  return [self rangeOfString:aString options:NSAnchoredSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, length)].location == 0;
}

- (BOOL)hasSuffixCaseInsensitive:(NSString *)aString {
  NSUInteger length = [aString length];
  if (length > [self length])
    return NO;
  return [self rangeOfString:aString options:NSAnchoredSearch | NSBackwardsSearch | NSCaseInsensitiveSearch range:NSMakeRange([self length] - length, length)].location != NSNotFound;
}

- (NSComparisonResult)numericCompare:(NSString *)aString {
  return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end

#pragma mark -
@implementation NSString (WBXMLEscaping)

- (NSString *)stringByEscapingEntities:(NSDictionary *)entities {
  NSString *str = (id)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)self, (CFDictionaryRef)entities);
  return [str autorelease];
}

- (NSString *)stringByUnescapingEntities:(NSDictionary *)entities {
  NSString *str = (id)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)self, (CFDictionaryRef)entities);
  if ([str length] == 0) {
    [str release];
    str = [self copy];
  }
  return [str autorelease];
}

@end

@implementation NSString (WBLineUtilities)

- (NSRange)rangeOfLine:(NSUInteger)line {
  return [self rangeOfLine:line inRange:NSMakeRange(0, [self length])];
}

- (NSRange)rangeOfLine:(NSUInteger)line inRange:(NSRange)aRange {
  NSRange range;
  NSUInteger idx = 0;
  NSUInteger lineNumber = 0;
  NSUInteger maximum = NSMaxRange(aRange);
  if (maximum > [self length])
		WBThrowException(NSRangeException, @"Range out of string limit.");

  NSRange (*GetLineRange)(id, SEL, NSRange);
  SEL selector = @selector(lineRangeForRange:);
  GetLineRange = (NSRange(*)(id, SEL, NSRange))[self methodForSelector:selector];
  WBAssert(GetLineRange, @"Error while getting %@", NSStringFromSelector(selector));

  // Find start of the first selected line
  do {
    range = GetLineRange(self, selector, NSMakeRange(idx, 0));
    idx = NSMaxRange(range);
    lineNumber++;
  } while (lineNumber < line && idx < maximum);
  if (lineNumber < line) {
    return NSMakeRange(NSNotFound, 0);
  }
  return range;
}

- (NSString *)stringByTrimmingWhitespace {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)stringByTrimmingWhitespaceAndNewline {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@implementation NSString (WBUtilities)

+ (id)localizedStringWithSize:(UInt64)size unit:(NSString *)unit precision:(NSUInteger)precision {
  if (size < ((UInt64)1 << 10))
    return [NSString stringWithFormat:@"%qu %@", size, unit];

  /* Kilo */
  if (size < ((UInt64)1 << 20))
    return [NSString localizedStringWithFormat:@"%.*f K%@", precision, (double)size / ((UInt64)1 << 10), unit];
  /* Mega */
  if (size < ((UInt64)1 << 30))
    return [NSString localizedStringWithFormat:@"%.*f M%@", precision, (double)size / ((UInt64)1 << 20), unit];
  /* Giga */
  if (size < ((UInt64)1 << 40))
    return [NSString localizedStringWithFormat:@"%.*f G%@", precision, (double)size / ((UInt64)1 << 30), unit];
  /* Tera */
  if (size < ((UInt64)1 << 50))
    return [NSString localizedStringWithFormat:@"%.*f T%@", precision, (double)size / ((UInt64)1 << 40), unit];
  /* Peta */
  if (size < ((UInt64)1 << 60))
    return [NSString localizedStringWithFormat:@"%.*f P%@", precision, (double)size / ((UInt64)1 << 50), unit];
  /* Exa */
  return [NSString localizedStringWithFormat:@"%.*f E%@", precision, (double)size / ((UInt64)1 << 60), unit];
}

@end
