/*
 *  WBWindowController.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

WB_CLASS_EXPORT
@interface WBWindowController : NSWindowController {
  @private
  struct _wb_wcFlags {
    unsigned int autorelease:1;
    unsigned int :7;
  } wb_wcFlags;
  NSInteger wb_modalStatus;
}

+ (NSString *)nibName;
+ (NSString *)frameAutoSaveName;

- (void)windowDidLoad;

- (BOOL)isReleasedWhenClosed;
- (void)setReleasedWhenClosed:(BOOL)release;

- (NSInteger)runModal:(BOOL)processRunLoop;

- (NSInteger)modalResultCode;
- (void)setModalResultCode:(NSInteger)code;

#pragma mark -
- (IBAction)close:(id)sender;

- (void)windowWillClose;

@end
