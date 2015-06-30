/*
 *  NSButton+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Cocoa/Cocoa.h>

@interface NSButton (WBImageButton)

- (id)initWithFrame:(NSRect)frame image:(NSImage *)anImage alternateImage:(NSImage *)altImage;

@end
