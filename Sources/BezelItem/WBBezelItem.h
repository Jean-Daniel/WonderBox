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
@interface WBBezelItem : NSObject

- (instancetype)initWithView:(NSView *)aView;
- (instancetype)initWithImage:(NSImage *)anImage;

@property(nonatomic, retain) NSView *view;
@property(nonatomic, retain) NSImage *anImage;

@property(nonatomic) NSTimeInterval delay;

- (IBAction)display:(id)sender;

@end
