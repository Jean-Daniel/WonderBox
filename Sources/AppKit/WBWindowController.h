/*
 *  WBWindowController.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>

WB_OBJC_EXPORT
@interface WBWindowController : NSWindowController {
  @private
  struct _wb_wcFlags {
    unsigned int autorelease:1;
    unsigned int :7;
  } wb_wcFlags;
  NSInteger wb_modalStatus;
}

+ (NSString *)nibName;
+ (NSBundle *)nibBundle;
+ (NSString *)frameAutoSaveName;

- (void)windowDidLoad;

- (BOOL)isReleasedWhenClosed;
- (void)setReleasedWhenClosed:(BOOL)release;

- (NSInteger)runModal:(BOOL)processRunLoop;

- (NSInteger)modalResultCode;
- (void)setModalResultCode:(NSInteger)code;

#pragma mark -
- (IBAction)close:(id)sender;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)windowWillClose;

@end
