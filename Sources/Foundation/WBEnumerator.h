/*
 *  WBEnumerator.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

WB_EXPORT
NSEnumerator *WBMapTableEnumerator(NSMapTable *table, BOOL keys);
