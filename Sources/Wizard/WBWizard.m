/*
 *  WBWizard.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBWizard.h)
#import WBHEADER(NSImage+WonderBox.h)

@interface WBWizard (PageLoading)
- (void)loadPage:(NSObject<WBWizardPage> *)aPage;
- (void)setPage:(NSObject<WBWizardPage> *)aPage;
@end

@implementation WBWizard

+ (NSString *)frameAutoSaveName {
  return nil;
}

- (id)init {
  return [self initWithPage:nil title:nil];
}

- (id)initWithPage:(NSObject<WBWizardPage> *)aPage {
  return [self initWithPage:aPage title:nil];
}

- (id)initWithPage:(NSObject<WBWizardPage> *)aPage title:(NSString *)windowTitle {
  if (self = [super init]) {
    wb_pages = [[NSMutableArray alloc] init];
    wb_wTitle = [windowTitle copy];
    if (aPage) [self loadPage:aPage];
  }
  return self;
}

- (void)dealloc {
  [wb_pages release];
  [wb_image release];
  [wb_object release];
  [wb_wTitle release];
  [wb_pageTitle release];
  [super dealloc];
}

#pragma mark -
#pragma mark Page Loading
- (void)windowDidLoad {
  [super windowDidLoad];
  if (wb_wTitle) [[self window] setTitle:wb_wTitle];
  NSButton *bClose = [[self window] standardWindowButton:NSWindowCloseButton];
  [bClose setTarget:self];
  [bClose setAction:@selector(cancel:)];

  [[self page] wizard:self willChangePage:WBWizardLoadNextPage];
  [self setPage:[self page]];
  [[self page] wizard:self didChangePage:WBWizardLoadNextPage];
}

- (void)loadPage:(NSObject<WBWizardPage> *)aPage {
  [aPage setWizard:self];
  [wb_pages addObject:aPage];
}

- (void)setPage:(NSObject<WBWizardPage> *)aPage {
  NSImage *img = [aPage image];
  [wizardImage setImage:img ? : [self defaultImage]];

  NSString *title = [aPage title];
  [wizardTitle setStringValue:title ? : [self defaultTitle]];

  NSView *view = [aPage pageView];
  WBAssert(view != nil, @"Warning: %@ return nil view", aPage);

  [view setFrameOrigin:NSZeroPoint];
  [view setFrameSize:[pageView frame].size];
  [[pageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [pageView addSubview:view];

  [next setEnabled:[aPage isComplete]];
  if ([self hasNext]) {
    [next setTitle:NSLocalizedStringFromTableInBundle(@"Continue", @"WBWizard", WBCurrentBundle(), @"Conitnue - Button")];
    [next setAction:@selector(next:)];
  } else {
    [next setTitle:NSLocalizedStringFromTableInBundle(@"Finish", @"WBWizard", WBCurrentBundle(), @"Finish - Button")];
    [next setAction:@selector(finish:)];
  }

  [previous setTitle:NSLocalizedStringFromTableInBundle(@"Go Back", @"WBWizard", WBCurrentBundle(), @"Go Back - Button")];
  [previous setEnabled:[self hasPrevious]];
  [previous setHidden:![self hasPrevious]];
}

- (void)pageDidChangeCompleteStatus {
  [next setEnabled:[[self page] isComplete]];
}

#pragma mark -
- (NSImage *)defaultImage {
  return wb_image ? : [NSImage imageNamed:@"WBWizard" inBundle:WBCurrentBundle()];
}

- (void)setDefaultImage:(NSImage *)anImage {
  WBSetterRetain(wb_image, anImage);
}

- (NSString *)defaultTitle {
  return wb_pageTitle ? : NSLocalizedStringFromTableInBundle(@"Assistant", @"WBWizard", WBCurrentBundle(), @"Default Title");
}

- (void)setDefaultTitle:(NSString *)aTitle {
  WBSetterCopy(wb_pageTitle, aTitle);
}

- (id)object {
  return wb_object;
}
- (void)setObject:(id)anObject {
  WBSetterRetain(wb_object, anObject);
}

- (id)delegate {
  return wb_delegate;
}
- (void)setDelegate:(id)aDelegate {
  wb_delegate = aDelegate;
}

#pragma mark -
#pragma mark IBActions
- (IBAction)next:(id)sender {
  if (![[self page] isComplete]) {
    NSBeep();
    return;
  }
  WBAssert([self hasNext], @"Cannot call next: on last page.");
  NSObject<WBWizardPage> *current = [self page];

  if ([current wizard:self shouldChangePage:WBWizardLeaveToNextPage]) {
    NSObject<WBWizardPage> *nextPage = [current nextPage];

    WBAssert(nextPage != nil, @"Invalid Next page.");
    wb_idx++;
    /* Check if next page is always the same and if not, flush all pages following the current page */
    if (wb_idx < [wb_pages count] && [wb_pages objectAtIndex:wb_idx] != nextPage) {
      [wb_pages removeObjectsInRange:NSMakeRange(wb_idx, [wb_pages count] - wb_idx)];
    }
    if (wb_idx >= [wb_pages count]) {
      [self loadPage:nextPage];
    }
    nextPage = [wb_pages objectAtIndex:wb_idx];

    [current wizard:self willChangePage:WBWizardLeaveToNextPage];
    [nextPage wizard:self willChangePage:WBWizardLoadNextPage];

    [self setPage:nextPage];

    [nextPage wizard:self didChangePage:WBWizardLoadNextPage];
    [current wizard:self didChangePage:WBWizardLeaveToNextPage];
  }
}

- (IBAction)previous:(id)sender {
  WBAssert(wb_idx > 0, @"Cannot call previous when first page is loaded");
  NSObject<WBWizardPage> *current = [self page];
  if ([current wizard:self shouldChangePage:WBWizardLeaveToPreviousPage]) {
    /* Should decrement after getting current page because we use idx in -page method. */
    wb_idx--;
    NSObject<WBWizardPage> *previousPage = [wb_pages objectAtIndex:wb_idx];

    [current wizard:self willChangePage:WBWizardLeaveToPreviousPage];
    [previousPage wizard:self willChangePage:WBWizardLoadPreviousPage];

    [self setPage:previousPage];

    [previousPage wizard:self didChangePage:WBWizardLoadPreviousPage];
    [current wizard:self didChangePage:WBWizardLeaveToPreviousPage];
  }
}

- (IBAction)finish:(id)sender {
  if ([[self page] wizard:self shouldChangePage:WBWizardFinish]) {
    [[self page] wizard:self willChangePage:WBWizardFinish];
    [self setModalResultCode:NSOKButton];
    if (WBDelegateHandle(wb_delegate, wizard:willClose:))
      [wb_delegate wizard:self willClose:WBWizardFinish];
    [self close:sender];
  }
}

- (IBAction)cancel:(id)sender {
  if ([[self page] wizard:self shouldChangePage:WBWizardCancel]) {
    [[self page] wizard:self willChangePage:WBWizardCancel];
    [self setModalResultCode:NSCancelButton];
    if (WBDelegateHandle(wb_delegate, wizard:willClose:))
      [wb_delegate wizard:self willClose:WBWizardCancel];
    [self close:sender];
  }
}

#pragma mark -
- (NSObject<WBWizardPage> *)page {
  return [wb_pages objectAtIndex:wb_idx];
}
- (NSObject<WBWizardPage> *)firstPage {
  return [wb_pages objectAtIndex:0];
}

- (BOOL)hasNext {
  return (wb_idx < [wb_pages count] -1) || [[self page] hasNext];
}
- (BOOL)hasPrevious {
  return wb_idx > 0;
}

@end
