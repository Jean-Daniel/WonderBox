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

+ (NSAlert *)alertWithMessageText:(nullable NSString *)message informativeText:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    alert.informativeText = text;
    return alert;
}

+ (NSAlert *)alertWithMessageText:(nullable NSString *)message informativeTextWithFormat:(NSString *)format, ... {
    va_list argList;
    va_start(argList, format);
    NSString *text = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [self alertWithMessageText:message informativeText:text];
}

- (void)bindSuppressionButtonToUserDefault:(NSString *)key {
  self.showsSuppressionButton = YES;
  NSButton *box = self.suppressionButton;

  /* Bind CheckBox value to User Defaults */
  [box bind:@"value"
   toObject:[NSUserDefaultsController sharedUserDefaultsController]
withKeyPath:[@"values." stringByAppendingString:key]
    options:nil];
}

//- (NSInteger)runSheetModalForWindow:(NSWindow *)window {
//  [self beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
//    [NSApp stopModalWithCode:returnCode];
//  }];
//  return [NSApp runModalForWindow:self.window];
//}

@end
