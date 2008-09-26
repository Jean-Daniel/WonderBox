/*
 *  WBExtensions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#pragma mark -
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

#pragma mark -
@interface NSArray (WBExtensions)
- (BOOL)containsObjectIdenticalTo:(id)anObject;
@end

@interface NSMutableDictionary (WBExtensions)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys;
@end

#pragma mark -
@interface NSData (WBHandleUtils)
+ (id)dataWithHandle:(Handle)handle;
- (id)initWithHandle:(Handle)handle;
@end
@interface NSMutableData (WBExtensions)
- (void)deleteBytesInRange:(NSRange)range;
@end

#pragma mark -
WB_EXPORT
CFCharacterSetRef WBCharacterSetGetNewLine(void) AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_5;
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
@interface NSCharacterSet (WBExtensions) 
+ (id)newlineCharacterSet;
@end
#endif

#pragma mark -
@interface NSError (WBExtensions)

+ (id)fileErrorWithCode:(NSInteger)code path:(NSString *)aPath;
+ (id)fileErrorWithCode:(NSInteger)code url:(NSURL *)anURL;

- (BOOL)isCancel;

@end

#pragma mark -
@interface NSInvocation (WBExtensions)
+ (id)invocationWithTarget:(id)target selector:(SEL)action;
@end

#pragma mark -
@interface WBIndexEnumerator : NSObject {
  @private
  NSIndexSet *wb_indexes;
  
  NSRange wb_range;
  NSUInteger wb_idx;
  NSUInteger wb_count;
  NSUInteger wb_buffer[32];
}

- (NSUInteger)nextIndex;

@end

@interface NSIndexSet (WBExtensions)
- (NSArray *)toArray;
- (WBIndexEnumerator *)indexEnumerator;
@end
