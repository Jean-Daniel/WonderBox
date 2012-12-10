/*
 *  WBWizardPage.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBWizard.h>

@class WBWizard;
WB_OBJC_EXPORT
@interface WBWizardPage : NSViewController <WBWizardPage> {
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
