/*
 *  WBBezelWindow.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBNotificationWindow.h>

@interface WBBezelWindow : WBNotificationWindow

+ (instancetype)windowWithImageView:(NSImageView *)aView;

@property(nonatomic, readonly) NSImageView *imageView;

@end

@interface WBBezelWindow (WBBezelLevelAbstract)

@property(nonatomic, getter=isLevelBarVisible) BOOL levelBarVisible;
@property(nonatomic) CGFloat levelValue;

@end

@interface WBBezelWindow ()
// Private
- (instancetype)initWithImageView:(NSImageView *)aView;
@end
