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

NSString *const kWBSerializationIsaKey = @"isa";

#pragma mark Serialize
static
BOOL __WBSerializeInstance(id object, NSMutableDictionary *plist, void *ctxt) {
  return [object respondsToSelector:@selector(serialize:)] ? [object serialize:plist] : NO;
}

NSDictionary *WBSerializeObject(id object, OSStatus *error) {
  return WBSerializeObjectWithFunction(object, error, __WBSerializeInstance, NULL);
}

id WBSerializeObjectWithFunction(id object, OSStatus *error, WBSerializeInstanceCallBack serialize, void *ctxt) {
  NSCParameterAssert(serialize);
  if (error) *error = noErr;
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  [plist setObject:NSStringFromClass([object classForCoder]) forKey:kWBSerializationIsaKey];
  @try {
    if (serialize(object, plist, ctxt))
      return plist;
  } @catch (id exception) {
    SPXCLogException(exception);
  }
  if (error)
    *error = kWBInstanceSerializationError;
  return nil;
}

#pragma mark -
#pragma mark Deserialize
static
id __WBDeserializeInstance(Class cls, NSDictionary *plist, void *ctxt) {
  return [cls instancesRespondToSelector:@selector(initWithSerializedValues:)] ? [[cls alloc] initWithSerializedValues:plist] : nil;
}

id WBDeserializeObject(NSDictionary *plist, OSStatus *error) {
  return WBDeserializeObjectWithFunction(plist, error, __WBDeserializeInstance, NULL);
}

id WBDeserializeObjectWithFunction(NSDictionary *plist, OSStatus *error, WBDeserializeInstanceCallBack deserialize, void *ctxt) {
  NSCParameterAssert(plist);
  NSCParameterAssert(deserialize);
  id object = nil;
  OSStatus err = noErr;
  if (error) *error = noErr;
  if (plist) {
    Class class = NSClassFromString(plist[kWBSerializationIsaKey]);
    if (!class) {
      err = kWBClassNotFoundError;
    } else {
      @try {
        object = deserialize(class, plist, ctxt);
      } @catch (id exception) {
        SPXCLogException(exception);
        object = nil;
      }
      if (!object) {
        err = kWBInstanceCreationError;
      }
    }
  }
  if (error)
    *error = err;
  return object;
}
