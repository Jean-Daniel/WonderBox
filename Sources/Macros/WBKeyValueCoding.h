/*
 *  WBKeyValueCoding.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

/* WARNING: should be capitalized key */
#define WBKeyValueCodingDeclaration(key) \
\
- (NSUInteger)countOf##key; \
- (id)objectIn##key##AtIndex:(NSUInteger)idx; \
- (void)get##key:(id *)objects range:(NSRange)aRange; \
\
- (void)insertObject:(id)anObject in##key##AtIndex:(NSUInteger)idx; \
- (void)removeObjectFrom##key##AtIndex:(NSUInteger)idx; \
- (void)replaceObjectIn##key##AtIndex:(NSUInteger)idx withObject:(id)anObject;


#define WBKeyValueCodingDefinition(key, ivar) \
 \
- (NSUInteger)countOf##key { \
	return [ivar count]; \
} \
 \
- (id)objectIn##key##AtIndex:(NSUInteger)idx { \
	return [ivar objectAtIndex:idx]; \
} \
 \
- (void)get##key:(id *)objects range:(NSRange)aRange { \
	[ivar getObjects:objects range:aRange]; \
} \
 \
- (void)insertObject:(id)anObject in##key##AtIndex:(NSUInteger)idx { \
	[ivar insertObject:anObject atIndex:idx]; \
} \
 \
- (void)removeObjectFrom##key##AtIndex:(NSUInteger)idx { \
	[ivar removeObjectAtIndex:idx]; \
} \
 \
- (void)replaceObjectIn##key##AtIndex:(NSUInteger)idx withObject:(id)anObject { \
	[ivar replaceObjectAtIndex:idx withObject:anObject]; \
}
