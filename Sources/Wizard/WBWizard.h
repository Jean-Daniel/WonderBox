/*
 *  WBWizard.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBWindowController.h)

enum {
  WBWizardCancel,
  WBWizardFinish,
  WBWizardLoadNextPage,
  WBWizardLeaveToNextPage,
  WBWizardLoadPreviousPage,
  WBWizardLeaveToPreviousPage,
};
typedef NSUInteger WBWizardOperation;

@class WBWizard;
@protocol WBWizardPage

- (NSImage *)image;
- (NSString *)title;

- (BOOL)hasNext;
- (BOOL)isComplete;

- (NSObject<WBWizardPage> *)nextPage;

- (NSView *)pageView;

- (void)setWizard:(WBWizard *)theWizard;

- (BOOL)wizard:(WBWizard *)theWizard shouldChangePage:(WBWizardOperation)operation;
- (void)wizard:(WBWizard *)theWizard willChangePage:(WBWizardOperation)operation;
- (void)wizard:(WBWizard *)theWizard didChangePage:(WBWizardOperation)operation;

@end

WB_OBJC_EXPORT
@interface WBWizard : WBWindowController {
  @private
  IBOutlet NSView *pageView;
  IBOutlet NSTextField *wizardTitle;
  IBOutlet NSImageView *wizardImage;
  IBOutlet NSButton *next, *previous;

  @private
  NSUInteger wb_idx;

  id wb_object;
  id wb_delegate;
  NSImage *wb_image;
  NSString *wb_wTitle;
  NSString *wb_pageTitle;
  NSMutableArray *wb_pages;
}

- (id)initWithPage:(NSObject<WBWizardPage> *)aPage;
- (id)initWithPage:(NSObject<WBWizardPage> *)aPage title:(NSString *)windowTitle;

- (id)object;
- (void)setObject:(id)anObject;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)finish:(id)sender;

- (BOOL)hasNext;
- (BOOL)hasPrevious;

- (NSObject<WBWizardPage> *)page;
- (NSObject<WBWizardPage> *)firstPage;

- (NSImage *)defaultImage;
- (void)setDefaultImage:(NSImage *)anImage;

- (NSString *)defaultTitle;
- (void)setDefaultTitle:(NSString *)aTitle;

- (void)pageDidChangeCompleteStatus;

@end

@interface NSObject (WBWizardDelegate)

- (void)wizard:(WBWizard *)theWizard willClose:(WBWizardOperation)operation;

@end

