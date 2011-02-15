/*
 *  WBBezelItem.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBNotificationWindow.h)

WB_OBJC_EXPORT
@interface WBBezelItem : WBNotificationWindow {

}

- (id)initWithContent:(id)content;

- (id)content;
- (void)setContent:(id)content;

- (NSUInteger)radius;
- (void)setRadius:(NSUInteger)aRadius;

- (BOOL)adjustSize;
- (void)setAdjustSize:(BOOL)flag;

@end
