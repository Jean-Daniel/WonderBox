/*
 *  NSAlert+WonderBox.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(NSAlert+WonderBox.h)

@implementation NSAlert (WBUserDefaultCheckBox)

- (NSButton *)addUserDefaultCheckBoxWithTitle:(NSString *)title andKey:(NSString *)key {
  NSParameterAssert(nil != title);
  
  NSButton *box = [[NSButton alloc] initWithFrame:NSMakeRect(20, 22, 16, 150)];
  /* Set Small Size */
  [[box cell] setControlSize:NSSmallControlSize];
  [box setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
  /* Configure Check Box */
  [box setButtonType:NSSwitchButton];
  [box setTitle:title];
  [box sizeToFit];
  
  /* Bind CheckBox value to User Defaults */
  if (key) {
    [box bind:@"value"    
     toObject:[NSUserDefaultsController sharedUserDefaultsController]
  withKeyPath:[@"values." stringByAppendingString:key]
      options:nil];
  }
  /* Add Check Box to Alert Window */
  [[[self window] contentView] addSubview:box];
  [box release];
  return box;
}

- (NSInteger)runSheetModalForWindow:(NSWindow *)window {
  [self beginSheetModalForWindow:window
                   modalDelegate:self
                  didEndSelector:@selector(wb_alertDidEnd:returnCode:contextInfo:)
                     contextInfo:nil];
  return [NSApp runModalForWindow:[self window]];
}

- (void)wb_alertDidEnd:(NSAlert *)alert returnCode:(NSUInteger)returnCode contextInfo:(void *)contextInfo {
  [NSApp stopModalWithCode:returnCode];
}

@end
