/*
 *  WBEnumerator.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBEnumerator.h>

@interface WBMapEnumerator : NSEnumerator {
  BOOL wb_key;
  NSMapEnumerator wb_enumerator;
}

- (id)initWithMapTableKeys:(NSMapTable *)table;
- (id)initWithMapTableValues:(NSMapTable *)table;

@end

NSEnumerator *WBMapTableEnumerator(NSMapTable *table, BOOL keys) {
  NSEnumerator *enumerator = keys ? [[WBMapEnumerator alloc] initWithMapTableKeys:table] :
  [[WBMapEnumerator alloc] initWithMapTableValues:table];
  return [enumerator autorelease];
}

#pragma mark -
@implementation WBMapEnumerator

- (id)init {
  [[self autorelease] doesNotRecognizeSelector:_cmd];
  return nil;
}

- (id)initWithMapTable:(NSMapTable *)table {
  NSParameterAssert(table);
  if (self = [super init]) {
    wb_enumerator = NSEnumerateMapTable(table);
  }
  return self;
}

- (id)initWithMapTableKeys:(NSMapTable *)table {
  if (self = [self initWithMapTable:table]) {
    wb_key = YES;
  }
  return self;
}

- (id)initWithMapTableValues:(NSMapTable *)table {
  if (self = [self initWithMapTable:table]) {
    wb_key = NO;
  }
  return self;
}

- (void)dealloc {
  NSEndMapTableEnumeration(&wb_enumerator);
  [super dealloc];
}

- (id)nextObject {
  void *object = NULL;
  if (NSNextMapEnumeratorPair(&wb_enumerator, wb_key ? &object : NULL, wb_key ? NULL : &object)) {
    return object;
  }
  return nil;
}

/* Warning: a map can contains something that's not an NSObject (ie: integer) */
- (NSArray *)allObjects {
  id object = nil;
  NSMutableArray *objects = [[NSMutableArray alloc] init];
  while (object = [self nextObject]) {
    [objects addObject:object];
  }
  return [objects autorelease];
}

@end
