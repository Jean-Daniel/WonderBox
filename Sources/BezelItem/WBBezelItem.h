/*
 *  WBBezelItem.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBNotificationWindow.h>

WB_OBJC_EXPORT
@interface WBBezelItem : WBNotificationWindow

- (instancetype)initWithContent:(id)content;

@property(nonatomic, retain) id content;

@property(nonatomic) NSUInteger radius;

@property(nonatomic) BOOL adjustSize;

@end
