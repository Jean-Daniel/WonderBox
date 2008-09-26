/*
 *  WBExtensions.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBExtensions.h)

#import <objc/objc-class.h>
#import WBHEADER(WBFunctions.h)

#pragma mark -
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
  NSAssert1(GetLineRange, @"Error while getting %@", NSStringFromSelector(selector));
  
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

#pragma mark -
@implementation NSArray (WBExtensions)

- (BOOL)containsObjectIdenticalTo:(id)anObject {
  return [self indexOfObjectIdenticalTo:anObject] != NSNotFound;
}

@end

@implementation NSMutableDictionary (WBExtensions)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys {
  NSUInteger count = [keys count];
  while (count-- > 0) {
    [self setObject:anObject forKey:[keys objectAtIndex:count]];
  }
}
@end

#pragma mark -
@implementation NSData (WBHandleUtils)

+ (id)dataWithHandle:(Handle)handle {
  return [[[self alloc] initWithHandle:handle] autorelease];
}

- (id)initWithHandle:(Handle)handle {
  if (handle)  { 
    self = [self initWithBytes:*handle length:GetHandleSize(handle)];
  } else {
    [self release];
    self = nil;
  } 
  return self;
}

@end

@implementation NSMutableData (WBExtensions)

- (void)deleteBytesInRange:(NSRange)range {
  CFDataDeleteBytes((CFMutableDataRef)self, CFRangeMake(range.location, range.length));
}

@end

#pragma mark -
@implementation NSCharacterSet (NewLineCharacterSet) 

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
CFCharacterSetRef WBCharacterSetGetNewLine() {
	if ((WBSystemMajorVersion() == 10 && WBSystemMinorVersion() >= 5) || WBSystemMajorVersion() > 10) {
		return CFCharacterSetGetPredefined(kCFCharacterSetNewline);		
	} else {
		static CFCharacterSetRef charset = nil;
		if (!charset) {
			UniChar chars[] = {0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029};
			CFStringRef string = CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 7);
			NSCAssert(string != nil, @"Unable to create new line string.");
			charset = CFCharacterSetCreateWithCharactersInString(kCFAllocatorDefault, string);
			CFRelease(string);
		}
		return charset;
	}
}

+ (id)newlineCharacterSet {
  return (NSCharacterSet *)WBCharacterSetGetNewLine();
}
#else
/* @deprecated */
CFCharacterSetRef WBCharacterSetGetNewLine() {
	return CFCharacterSetGetPredefined(kCFCharacterSetNewline);
}
#endif
@end

#pragma mark -
@implementation NSError (WBExtensions)

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath {
  NSDictionary *info = nil;
  if (aPath)
    info = [NSDictionary dictionaryWithObject:aPath forKey:NSFilePathErrorKey];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL {
  NSDictionary *info = nil;
  if (anURL)
    info = [NSDictionary dictionaryWithObject:anURL forKey:NSURLErrorKey];
  return [self errorWithDomain:NSCocoaErrorDomain code:code userInfo:info];
}

- (BOOL)isCancel {
  /* Cocoa */
  if ([[self domain] isEqualToString:NSCocoaErrorDomain] && [self code] == NSUserCancelledError)
    return YES;
  /* Carbon */
  if ([[self domain] isEqualToString:NSOSStatusErrorDomain] && [self code] == userCanceledErr)
    return YES;
  /* Posix */
  if ([[self domain] isEqualToString:NSPOSIXErrorDomain] && [self code] == ECANCELED)
    return YES;
  /* Mach */
	//  if ([[self domain] isEqualToString:NSMachErrorDomain] && [self code] == KERN_ABORTED)
	//    return YES;
  return NO;
}

@end

@implementation NSInvocation (WBExtensions)

+ (id)invocationWithTarget:(id)target selector:(SEL)action {
  if (![target respondsToSelector:action])
		WBThrowException(NSInvalidArgumentException, @"%@ does not responds to selector %@", 
										 target, NSStringFromSelector(action));
  
  NSMethodSignature *sign = [target methodSignatureForSelector:action];
  NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:sign];
  [invoc setTarget:target];
  [invoc setSelector:action];
  return invoc;
}

@end

#pragma mark -
@implementation WBIndexEnumerator

- (void)fillBuffer {
  wb_idx = 0;
  if (wb_indexes) {
    wb_count = [wb_indexes getIndexes:wb_buffer maxCount:32 inIndexRange:&wb_range];
    if (0 == wb_range.length) {
      // No longer need indexes
      [wb_indexes release];
      wb_indexes = nil;
    }
  } else {
    wb_count = 0;
  }
}

- (id)initWithIndexSet:(NSIndexSet *)indexes {
  if (self = [super init]) {
    wb_range = NSMakeRange([indexes firstIndex], [indexes lastIndex] - [indexes firstIndex] + 1);
    wb_indexes = [indexes retain];
    [self fillBuffer];
  }
  return self;
}

- (void)dealloc {
  [wb_indexes release];
  [super dealloc];
}

- (NSUInteger)nextIndex {
  if (wb_idx >= wb_count) {
    [self fillBuffer];
  }
  if (wb_count) {
    return wb_buffer[wb_idx++]; 
  } else {
    return NSNotFound; 
  }
}

@end

@implementation NSIndexSet (WBExtensions)

- (NSArray *)toArray {
  NSUInteger count = [self count];
  if (count == 0)
    return [NSArray array];
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];
  NSRange range = NSMakeRange([self firstIndex], [self lastIndex] - [self firstIndex] + 1);
  NSUInteger length;
  NSUInteger buffer[100];
  while (length = [self getIndexes:buffer maxCount:100 inIndexRange:&range]) {
    NSUInteger idx = 0;
    while (idx < length) {
      [array addObject:WBUInteger(buffer[idx])];
      idx++;
    }
    if (0 == range.length)
      break;
  }
  return [array autorelease];
}

- (WBIndexEnumerator *)indexEnumerator {
  return [[[WBIndexEnumerator alloc] initWithIndexSet:self] autorelease];
}

@end
