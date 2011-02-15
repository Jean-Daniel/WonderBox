/*
 *  WBSerialization.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBSerialization.h)

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
  BOOL ok = NO;
  if (error) *error = noErr;
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  [plist setObject:NSStringFromClass([object classForCoder]) forKey:kWBSerializationIsaKey];
  @try {
    ok = serialize(object, plist, ctxt);
  } @catch (id exception) {
    WBCLogException(exception);
  }
  if (ok) {
    [plist autorelease];
  } else {
    if (error) *error = kWBInstanceSerializationError;
    [plist release];
    plist = nil;
  }
  return plist;
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
    Class class = NSClassFromString([plist objectForKey:kWBSerializationIsaKey]);
    if (!class) {
      err = kWBClassNotFoundError;
    } else {
      @try {
        object = deserialize(class, plist, ctxt);
      } @catch (id exception) {
        object = nil;
        WBCLogException(exception);
      }
      if (!object) {
        err = kWBInstanceCreationError;
      } else {
        [object autorelease];
      }
    }
  }
  if (error) *error = err;
  return object;
}
