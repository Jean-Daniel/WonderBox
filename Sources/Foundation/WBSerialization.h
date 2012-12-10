/*
 *  WBSerialization.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

enum {
  kWBClassNotFoundError = 'Clnf',
  kWBInstanceCreationError = 'IstC',
  kWBInstanceSerializationError = 'IstS',
};

#pragma mark WBSerializable Protocol
@interface NSObject (WBSerializable)
- (id)initWithSerializedValues:(NSDictionary *)plist;
- (BOOL)serialize:(NSMutableDictionary *)aDictionary;
@end

WB_EXPORT
NSString *const kWBSerializationIsaKey;

#pragma mark Functions
WB_EXPORT
NSDictionary *WBSerializeObject(id object, OSStatus *error);
WB_EXPORT
id WBDeserializeObject(NSDictionary *plist, OSStatus *error);

#pragma mark -
#pragma mark CallBack based API
typedef BOOL (*WBSerializeInstanceCallBack)(id object, NSMutableDictionary *plist, void *ctxt);
typedef id (*WBDeserializeInstanceCallBack)(Class cls, NSDictionary *plist, void *ctxt);

WB_EXPORT
id WBSerializeObjectWithFunction(id object, OSStatus *error, WBSerializeInstanceCallBack callback, void *ctxt);
WB_EXPORT
id WBDeserializeObjectWithFunction(NSDictionary *plist, OSStatus *error, WBDeserializeInstanceCallBack callback, void *ctxt);
