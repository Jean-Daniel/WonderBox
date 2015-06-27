/*
 *  WBTemplate.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTemplate.h>
#import <WonderBox/WBTemplateParser.h>

@interface WBTemplate ()

- (id)initBlockWithName:(NSString *)name;

- (void)clear;
- (void)wb_init;
- (void)resetBlock;
- (void)resetVariables;

- (void)setName:(NSString *)aName;
@end

@implementation WBTemplate

- (void)wb_init {
  NSAssert(wb_contents == nil, @"WARNING: re-init template");
  wb_blocks = [[NSMutableArray alloc] init];
  wb_contents = [[NSMutableArray alloc] init];
  wb_vars = [[NSMutableDictionary alloc] init];
}

- (id)init {
  return [self initWithContentsOfFile:nil encoding:[NSString defaultCStringEncoding]];
}

- (id)initBlockWithName:(NSString *)name {
  if (self = [super init]) {
    [self wb_init];
    [self setName:name];
  }
  return self;
}

- (id)initWithContentsOfFile:(NSString *)aFile {
  SPXDebug(@"WARNING: deprecated fonction: %@", NSStringFromSelector(_cmd));
  return [self initWithContentsOfFile:aFile encoding:[NSString defaultCStringEncoding]];
}

- (id)initWithContentsOfFile:(NSString *)aFile encoding:(NSStringEncoding)encoding {
  if (self = [super init]) {
    [self setName:aFile];
    wb_encoding = encoding;
  }
  return self;
}

- (id)initWithContentsOfURL:(NSURL *)anURL encoding:(NSStringEncoding)encoding {
  return [self initWithContentsOfFile:anURL.path encoding:encoding];
}

- (NSStringEncoding)encoding {
  return wb_encoding;
}

- (void)setStringEncoding:(NSStringEncoding)encoding {
  wb_encoding = encoding;
}

- (void)dealloc {
  [wb_name release];
  [wb_vars release];
  [wb_blocks release];
  [wb_contents release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {name:%@ contents:%@ blocks:%@}",
    NSStringFromClass([self class]), self,
    [self name], wb_contents, wb_blocks];
}

#pragma mark -
- (NSString *)name {
  return wb_name;
}
- (void)setName:(NSString *)aName {
  if (wb_name != aName) {
    [wb_name release];
    wb_name = [aName copy];
  }
}

- (BOOL)removeBlockLine {
  return wb_tplFlags.removeBlockLine;
}
- (void)setRemoveBlockLine:(BOOL)flags {
  wb_tplFlags.removeBlockLine = flags ? 1 : 0;
}

#pragma mark Variables
- (BOOL)containsKey:(NSString *)key {
  if (!wb_contents) {
    [self load];
  }
  return [wb_vars objectForKey:key] != nil;
}

- (NSString *)variableForKey:(NSString *)aKey {
  id var = [wb_vars objectForKey:aKey];
  return ([var isMemberOfClass:[NSNull class]]) ? nil : var;
}

- (void)setVariable:(NSString *)aValue forKey:(NSString *)aKey {
  if (!wb_contents) {
    [self load];
  }
#ifdef DEBUG
  if ([wb_vars objectForKey:aKey] == nil) NSLog(@"Warning: Variable %@ undefined in block %@", aKey, [self name]);
#endif
  CFDictionaryReplaceValue((CFMutableDictionaryRef)wb_vars, aKey, (aValue ? : (id)[NSNull null]));
}

#pragma mark Blocks
- (BOOL)isBlock {
  return [self parent] != nil;
}

- (id)blockWithName:(NSString *)aName {
  if (!wb_contents) {
    [self load];
  }
  if ([aName isEqualToString:[self name]])
    return self;
  id child = [self firstChild];
  id block = nil;
  while (child) {
    if ((block = [child blockWithName:aName]))
      break;
    child = [child nextSibling];
  }
  return block;
}

/* Duming a block cause clear all sub-blocks */
- (void)dumpBlock {
  if (!wb_contents) {
    [self load];
  }
  id blocks = [[NSMutableDictionary alloc] init];
  NSUInteger count = [self count];
  for (NSUInteger idx = 0; idx < count; idx++) {
    WBTemplate *child = [self childAtIndex:idx];
    id block = child->wb_blocks;
    if ([block count] > 0) {
      id blockCp = [block copy];
      [blocks setObject:blockCp forKey:[child name]];
      [blockCp release];
      [child resetBlock];
    }
  }

  [wb_vars setObject:blocks forKey:@"_Blocks_"];
  [blocks release];

  NSDictionary *vars = [wb_vars copy];
  [wb_blocks addObject:vars];
  [vars release];

  [self resetVariables];
}

#pragma mark -
#pragma mark Reset
- (void)reset {
  [self resetBlock];
  [self resetVariables];
  [self makeChildrenPerformSelector:_cmd];
}

- (void)resetBlock {
  [wb_blocks removeAllObjects];
  [self makeChildrenPerformSelector:_cmd];
}

- (void)resetVariables {
	NSString *key;
	/* cannot use keyEnumerator because we want to modify the dictionary during enumeration */
  NSEnumerator *keys = [[wb_vars allKeys] objectEnumerator];
  while (key = [keys nextObject]) {
		/* should use CF function to avoid "change while enumerate" exception" */
		CFDictionaryReplaceValue((CFMutableDictionaryRef)wb_vars, key, [NSNull null]);
  }
}

#pragma mark Clear
- (void)clear {
  if (wb_vars != nil) {
    [wb_vars release];
    wb_vars = nil;
  }
  if (wb_blocks != nil) {
    [wb_blocks release];
    wb_blocks = nil;
  }
  if (wb_contents != nil) {
    [wb_contents release];
    wb_contents = nil;
  }
}

#pragma mark -
#pragma mark Input
- (BOOL)load {
  if ([self isBlock]) {
		SPXThrowException(NSInvalidArgumentException, @"Cannot load a block template.");
  }
  if (wb_contents) {
    SPXDebug(@"WARNING: Template already loaded");
    return YES;
  }
  return [self loadFile:wb_name];
}

- (BOOL)loadFile:(NSString *)aFile {
  [self clear];
  BOOL result = NO;
  if (aFile) {
    [self wb_init];

    WBTemplateParser *parser = [[WBTemplateParser alloc] initWithFile:aFile encoding:wb_encoding];
    [parser setDelegate:self];
    @try {
      result = [parser parse];
    } @catch (id exception) {
      [self clear];
      SPXLogException(exception);
    }
    [parser release];
  }
  return result;
}

#pragma mark Introspection
- (NSArray *)allKeys {
  if (!wb_contents) {
    [self load];
  }
  return [wb_vars allKeys];
}

- (NSArray *)allBlocks {
  if (!wb_contents) {
    [self load];
  }
  return [self children];
}

- (NSDictionary *)structure {
  if (!wb_contents) {
    [self load];
  }
  NSMutableDictionary *struc = [[NSMutableDictionary alloc] init];
  NSMutableArray *content = [[NSMutableArray alloc] init];
  if ([self isBlock]) {
    [struc setObject:[self name] forKey:@"name"];
  } else {
    [struc setObject:[[self name] lastPathComponent] forKey:@"name"];
  }
  NSUInteger count = [wb_contents count];
  for (NSUInteger idx = 0; idx < count; idx++) {
    NSString *var = [wb_contents objectAtIndex:idx];
    /* if Var or Block */
    if (idx % 2) {
      id string = [wb_vars objectForKey:var];
      if (string) {
        /* string is a variable */
        [content addObject:var];
      } else {
        /* string is a block */
        id child = [self blockWithName:var];
        if (child) {
          [content addObject:[child structure]];
        }
      }
    }
//  else {
//      /* Simple text */
//      [struc addObject:var];
//	}
  }
  [struc setObject:content forKey:@"content"];
  [content release];
  return [struc autorelease];
}

#pragma mark Output
- (void)writeBlock:(NSDictionary *)block inBuffer:(NSMutableString *)buffer {
  NSUInteger count = [wb_contents count];
  for (NSUInteger idx = 0; idx < count; idx++) {
    NSString *var = [wb_contents objectAtIndex:idx];
    if (idx % 2) {  /* Var or Block */
      id string = [block objectForKey:var];
      if (string) { /* string is a variable */
        if (![string isMemberOfClass:[NSNull class]])
          [buffer appendString:string];
      } else { /* string is a block */
        WBTemplate *child = [self blockWithName:var];
        if (child) {
          NSDictionary *item;
          NSEnumerator *items = [[[block objectForKey:@"_Blocks_"] objectForKey:[child name]] objectEnumerator];
          while (item = [items nextObject]) {
            [child writeBlock:item inBuffer:buffer];
          }
        }
      }
    } else { /* String Value */
      [buffer appendString:var];
    }
  }
}

- (NSString *)stringRepresentation {
  NSMutableString *result = [NSMutableString string];
  if (![self isBlock]) /* If root then dump */
    [self dumpBlock];
  NSUInteger count = [wb_blocks count];
  for (NSUInteger idx = 0; idx < count; idx++) {
    [self writeBlock:[wb_blocks objectAtIndex:idx] inBuffer:result];
  }
  return result;
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag andReset:(BOOL)reset {
  @autoreleasepool {
    NSString *result = [self stringRepresentation];

    BOOL ok = [result writeToFile:file atomically:flag encoding:wb_encoding error:nil];
    if (reset)
      [self reset];
    return ok;
  }
}

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)flag andReset:(BOOL)reset {
  return [self writeToFile:url.path atomically:flag andReset:reset];
}

#pragma mark -
#pragma mark Parser Delegate
- (void)templateParser:(WBTemplateParser *)parser foundCharacters:(NSString *)aString {
  if (wb_tplFlags.removeBlockLine && (wb_tplFlags.inBlock || ([self isBlock] && [wb_contents count] == 0))) {
    NSUInteger idx = [aString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location;
    if (idx != NSNotFound)
      aString = [aString substringFromIndex:idx + 1];
  }
  [wb_contents addObject:aString];
  if (wb_tplFlags.inBlock)
    wb_tplFlags.inBlock = 0;
}

- (void)templateParser:(WBTemplateParser *)parser foundVariable:(NSString *)variable {
  [wb_contents addObject:variable];
  [wb_vars setObject:[NSNull null] forKey:variable];
}

- (void)templateParser:(WBTemplateParser *)parser didStartBlock:(NSString *)blockName {
  id child = [[[self class] alloc] initBlockWithName:blockName];
  [child setRemoveBlockLine:[self removeBlockLine]];
  wb_tplFlags.inBlock = 1;
  [self appendChild:child];
  [parser setDelegate:child];
  [child release];
  [wb_contents addObject:blockName];
}

- (void)templateParserDidEndBlock:(WBTemplateParser *)parser {
  [parser setDelegate:[self parent]];
}

@end
