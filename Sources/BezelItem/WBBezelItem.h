/*
 *  WBBezelItem.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

WB_OBJC_EXPORT
@interface WBBezelItem : NSObject

/*!
 create an instance without level bar.
 */
- (instancetype)initWithImage:(nullable NSImage *)anImage NS_DESIGNATED_INITIALIZER;

/*!
 create an instance with level bar visible.
 */
- (instancetype)initWithImage:(nullable NSImage *)anImage level:(CGFloat)aLevel;

@property(nonatomic, retain, nullable) NSImage *image;

@property(nonatomic) NSTimeInterval duration;

@property(nonatomic, getter=isLevelBarVisible) BOOL levelBarVisible;

@property(nonatomic) CGFloat levelValue;

- (IBAction)display:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
