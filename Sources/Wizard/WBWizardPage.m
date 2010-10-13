/*
 *  WBWizardPage.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBWizardPage.h)

@implementation WBWizardPage

+ (NSString *)pageNibName {
  return NSStringFromClass(self);
}

+ (id)page {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  if (self = [super initWithNibName:[[self class] pageNibName] bundle:WBCurrentBundle()]) {

  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (NSImage *)image {
  return nil;
}
- (NSString *)title {
  return nil;
}

- (BOOL)hasNext {
  return NO;
}
- (BOOL)isComplete {
  return YES;
}

- (NSObject<WBWizardPage> *)nextPage {
  return nil;
}

- (WBWizard *)wizard {
  return wb_wizard;
}
- (void)setWizard:(WBWizard *)theWizard {
  wb_wizard = theWizard;
}

- (NSWindow *)window {
  return [[self wizard] window];
}

- (NSView *)pageView {
  return [self view];
}

- (void)pageDidChangeCompleteStatus {
  [[self wizard] pageDidChangeCompleteStatus];
}

/* Handle operations */
- (void)cancel {
}
- (void)finish {
}
- (id)object {
  return [[self wizard] object];
}
- (id)createObject {
  return nil;
}
- (BOOL)loadObject:(id)anObject {
  return YES;
}
- (void)wizardWillLoadPage {
}
- (void)wizardDidLoadPage {
}
- (void)wizardWillLeavePage {
}
- (void)wizardDidLeavePage {
}

/* Wizard actions */
- (void)wizard:(WBWizard *)theWizard willChangePage:(WBWizardOperation)operation {
  switch (operation) {
    case WBWizardFinish:
      [self finish];
      [self loadObject:nil];
      break;
    case WBWizardCancel:
      [self cancel];
      [self loadObject:nil];
      break;
    case WBWizardLoadNextPage:
    case WBWizardLoadPreviousPage: {
      [self view]; // make sure the nib is loaded
      [self wizardWillLoadPage];
      id object = [theWizard object];
      if (object && [self loadObject:object]) {
        [theWizard willChangeValueForKey:@"object"];
        [theWizard didChangeValueForKey:@"object"];
      } else {
        [theWizard setObject:[self createObject]];
        [self loadObject:[theWizard object]];
      }
    }
      break;
    case WBWizardLeaveToNextPage:
    case WBWizardLeaveToPreviousPage:
      [self wizardWillLeavePage];
      break;
    default:
      break;
  }
}

- (void)wizard:(WBWizard *)theWizard didChangePage:(WBWizardOperation)operation {
  switch (operation) {
    case WBWizardLoadNextPage:
    case WBWizardLoadPreviousPage:
      [self wizardDidLoadPage];
      break;
    case WBWizardLeaveToNextPage:
    case WBWizardLeaveToPreviousPage:
      [self wizardDidLeavePage];
      [self loadObject:nil];
      break;
    default:
      break;
  }
}

- (BOOL)wizard:(WBWizard *)theWizard shouldChangePage:(WBWizardOperation)operation {
  return YES;
}

@end
