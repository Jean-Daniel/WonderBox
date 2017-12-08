/*
 *  WBSerialization.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBSerialization.h>

@interface NSObject (WBSerializationLegacy)
- (id)initWithSerializedValues:(NSDictionary *)plist;
@end

NSString *const kWBSerializationIsaKey = @"isa";

// MARK: Serialize
NSDictionary *WBSerializeObject(id<WBSerializable> object, NSError * __autoreleasing *error) {
  NSCParameterAssert(object);

  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  Class cls = [object respondsToSelector:@selector(classForCoder)] ? [object classForCoder] : [object class];
  [plist setObject:NSStringFromClass(cls) forKey:kWBSerializationIsaKey];
  @try {
    if ([object serialize:plist])
      return plist;
  } @catch (id exception) {
    SPXCLogException(exception);
  }
  if (error)
    *error = [NSError errorWithDomain:@"com.xenonium.wonderbox" code:kWBInstanceSerializationError userInfo:nil];
  return nil;
}

id<WBSerializable> WBDeserializeObject(NSDictionary *plist, NSError * __autoreleasing *error) {
  NSCParameterAssert(plist);
  NSInteger err = 0;
  Class cls = NSClassFromString(plist[kWBSerializationIsaKey]);
  if (!cls) {
    err = kWBClassNotFoundError;
  } else {
    @try {
      id obj = [[cls alloc] initWithSerializedValues:plist];
      if (obj)
        return obj;
    } @catch (id exception) {
      SPXCLogException(exception);
    }
    err = kWBInstanceCreationError;
  }
  if (error)
    *error = [NSError errorWithDomain:@"com.xenonium.wonderbox" code:err userInfo:nil];;
  return nil;
}

