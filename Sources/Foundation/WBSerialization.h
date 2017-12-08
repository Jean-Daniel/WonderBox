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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum {
  kWBClassNotFoundError = 'Clnf',
  kWBInstanceCreationError = 'IstC',
  kWBInstanceSerializationError = 'IstS',
};

// MARK: WBSerializable Protocol
@protocol WBSerializable <NSObject>
@optional
- (Class)classForCoder;
@required
- (nullable id)initWithSerializedValues:(NSDictionary *)plist;
- (BOOL)serialize:(NSMutableDictionary *)aDictionary;
@end

WB_EXPORT
NSString *const kWBSerializationIsaKey;

// MARK: Functions
WB_EXPORT
NSDictionary *WBSerializeObject(id<WBSerializable> object, NSError * __autoreleasing *error);
WB_EXPORT
id<WBSerializable> WBDeserializeObject(NSDictionary *plist, NSError * __autoreleasing *error);

NS_ASSUME_NONNULL_END

