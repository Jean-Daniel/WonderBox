/*
 *  WBIconView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBIconView
    @abstract NSView subclass designed to draw Carbon <code>IconRef</code>.
    @discussion WBIconView is usefull if you want to draw icon without the overhead of icon to NSImage conversion.
*/

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

WB_OBJC_EXPORT
@interface WBIconView : NSView {
  @private
  IconRef wb_icon;
}

- (IconRef)iconRef;
- (void)setIconRef:(IconRef)anIcon;

- (void)setSystemIcon:(OSType)icon;

@end
