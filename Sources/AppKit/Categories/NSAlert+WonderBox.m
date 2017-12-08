/*
 *  NSAlert+WonderBox.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSAlert+WonderBox.h>

@implementation NSAlert (WBUserDefaultCheckBox)

- (void)bindSuppressionButtonToUserDefault:(NSString *)key {
  self.showsSuppressionButton = YES;
  NSButton *box = self.suppressionButton;

  /* Bind CheckBox value to User Defaults */
  [box bind:@"value"
   toObject:[NSUserDefaultsController sharedUserDefaultsController]
withKeyPath:[@"values." stringByAppendingString:key]
    options:nil];
}

- (NSInteger)runSheetModalForWindow:(NSWindow *)window {
  [self beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
    [NSApp stopModalWithCode:returnCode];
  }];
  return [NSApp runModalForWindow:[self window]];
}

@end
