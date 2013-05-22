/*
 *  WBAsynchronousValueLoader.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2013 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBAsynchronousValueLoader.h"

#import <objc/runtime.h>

@interface WBAsynchronousProperty : NSObject {
@public
  id value;
  WBKeyValueStatus status;
}

@end

@implementation WBAsynchronousProperty

- (instancetype)init {
  if (self = [super init]) {
    status = WBKeyValueStatusUnknown;
  }
  return self;
}

@end

@interface WBAsynchronousPropertyRequest : NSObject {
@public
  NSMutableSet *keys;
  void (^handler)(void);
}

@end

@implementation WBAsynchronousPropertyRequest

@end

// MARK: -
@implementation WBAsynchronousValueLoader {
@private
  NSMutableArray *_requests;
  __unsafe_unretained id _owner;
  NSMutableDictionary *_properties;
}

- (id)initWithOwner:(id)owner {
  if (self = [super init]) {
    _owner = owner;
  }
  return self;
}

// MARK: Property handling
- (id)propertyforKey:(NSString *)name {
  WBAsynchronousProperty *property = [_properties objectForKey:name];
  return property != nil && property->status == WBKeyValueStatusLoaded ? property->value : nil;
}

- (void)setProperty:(id)value forKey:(NSString *)name status:(WBKeyValueStatus)status {
  dispatch_async(dispatch_get_main_queue(), ^{
    WBAsynchronousProperty *property = [_properties objectForKey:name];
    if (property && property->status != WBKeyValueStatusCancelled) {
      property->value = value;
      // Do not notify if the status did not change (updating the cached value of a loaded property)
      if (property->status != status) {
        property->status = status;

        // Check pending requests.
        NSUInteger idx = [_requests count];
        while (idx-- > 0) {
          WBAsynchronousPropertyRequest *req = [_requests objectAtIndex:idx];
          [req->keys removeObject:name];
          if (![req->keys count]) {
            [_requests removeObjectAtIndex:idx];
            if (req->handler)
              req->handler();
          }
        }
      }
    }
  });
}

- (void)setProperty:(id)value forKey:(NSString *)name {
  [self setProperty:value forKey:name status:WBKeyValueStatusLoaded];
}

- (void)setPropertyError:(NSError *)value forKey:(NSString *)name {
  [self setProperty:value forKey:name status:WBKeyValueStatusFailed];
}

- (WBKeyValueStatus)statusOfValueForKey:(NSString *)key error:(NSError **)outError {
  WBAsynchronousProperty *property = [_properties objectForKey:key];
  if (!property)
    return WBKeyValueStatusUnknown;

  if (WBKeyValueStatusFailed == property->status && outError) {
    *outError = property->value;
  }
  return property->status;
}

typedef void (*VOID_IMP)(id, SEL);

// TODO: improve to support sync properties.
static inline
bool fetchProperty(id self, NSString *property) {
  if (!class_getProperty([self class], [property UTF8String]))
    return false;

  NSString *selname = [@"fetch" stringByAppendingString:[property capitalizedString]];
  SEL action = NSSelectorFromString(selname);
  VOID_IMP method = (VOID_IMP)[self methodForSelector:action];
  if (method) {
    method(self, action);
    return true;
  }
  return false;
}

- (void)loadValuesAsynchronouslyForKeys:(NSArray *)keys completionHandler:(void (^)(void))handler {
  bool done = true;
  for (NSString *key in keys) {
    WBAsynchronousProperty *property = [_properties objectForKey:key];
    if (!property) {
      property = [WBAsynchronousProperty new];
      if (fetchProperty(_owner, key)) {
        done = false;
        // start loading.
        property->status = WBKeyValueStatusLoading;
      } else {
        property->status = WBKeyValueStatusFailed;
        property->value = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil];
      }
      if (!_properties)
        _properties = [NSMutableDictionary new];
      [_properties setObject:property forKey:key];
    } else if (property->status == WBKeyValueStatusLoading) {
      done = false;
    }
  }

  // check request in case everything is already OK.
  if (done) {
    if (handler)
      dispatch_async(dispatch_get_main_queue(), handler);
  } else {
    if (!_requests)
      _requests = [NSMutableArray new];

    // Create a load request.
    WBAsynchronousPropertyRequest *request = [WBAsynchronousPropertyRequest new];
    request->keys = [NSMutableSet setWithArray:keys];
    request->handler = handler;
    [_requests addObject:request];
  }
}

- (void)invalidateProperty:(NSString *)key {
  [_properties removeObjectForKey:key];
}
- (void)invalidateAllProperties {
  [_properties removeAllObjects];
}

- (void)cancelLoading {
  // TODO: define a way to stop loading.
  for (WBAsynchronousProperty *property in [_properties objectEnumerator]) {
    if (WBKeyValueStatusLoading == property->status)
      property->status = WBKeyValueStatusCancelled;
  }
}

@end
