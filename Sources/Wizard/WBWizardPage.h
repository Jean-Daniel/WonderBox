/*
 *  XEWizardPage.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBViewController.h)
#import WBHEADER(WBWizard.h)

@class WBWizard;
WB_CLASS_EXPORT
@interface WBWizardPage : WBViewController <WBWizardPage> {
  @private
  WBWizard *wb_wizard;
}

+ (NSString *)pageNibName;

+ (id)page;
- (id)init;

- (NSImage *)image;
- (NSString *)title;

- (BOOL)hasNext;
- (BOOL)isComplete;

- (NSObject<WBWizardPage> *)nextPage;

- (WBWizard *)wizard;
- (void)setWizard:(WBWizard *)theWizard;

- (void)cancel;
- (void)finish;

- (id)createObject;
- (BOOL)loadObject:(id)anObject;

- (void)wizardWillLoadPage;
- (void)wizardDidLoadPage;

- (void)wizardWillLeavePage;
- (void)wizardDidLeavePage;

/* convenient methods (just call wizard methods) */
- (id)object;
- (NSWindow *)window;
- (void)pageDidChangeCompleteStatus;

@end
