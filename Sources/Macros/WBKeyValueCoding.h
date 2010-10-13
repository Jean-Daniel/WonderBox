/*
 *  WBKeyValueCoding.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
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
