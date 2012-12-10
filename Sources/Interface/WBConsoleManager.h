/*
 *  WBConsoleManager.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

WB_OBJC_EXPORT
@interface WBConsoleManager : NSObject {
  @private
  id wb_delegate;

  NSString *wb_prompt;
  NSUInteger wb_uneditable;

  NSTextView *wb_text;

  NSUInteger wb_historyLine;
  NSUInteger wb_historySize;
  NSMutableArray *wb_history;

  NSColor *wb_userColor;
  NSColor *wb_systemColor;

  NSMutableString *wb_queue;
  struct _wb_cmFlags {
    unsigned int lock:1;
    unsigned int execute:1;
    unsigned int disabled:1;
    unsigned int :5;
  } wb_cmFlags;
}

- (NSString *)prompt;
- (void)setPrompt:(NSString *)aString;

- (NSFont *)font;
- (void)setFont:(NSFont *)aFont;

- (NSTextView *)textView;
- (void)setTextView:(NSTextView *)aView;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (NSString *)lastCommand;

- (IBAction)clear:(id)sender;
- (IBAction)prompt:(id)sender;

/* Append an editable interpreted string */
- (void)appendUserString:(NSString *)str;

/* Append an uneditable string */
- (void)appendSystemString:(NSString *)str;

- (void)appendSystemString:(NSString *)str link:(id)link;
- (void)appendSystemFormat:(NSString *)format link:(id)aLink, ...;

- (void)appendSystemString:(NSString *)str color:(NSColor *)aColor;
- (void)appendSystemFormat:(NSString *)format color:(NSColor *)aColor, ...;

- (void)appendSystemString:(NSString *)str attributes:(NSDictionary *)attributes;
- (void)appendSystemFormat:(NSString *)format attributes:(NSDictionary *)attributes, ...;
- (void)appendSystemFormat:(NSString *)format attributes:(NSDictionary *)attributes arguments:(va_list)args;

/* Use by asynchronous delegate */
- (void)lock;
- (void)unlock;
- (BOOL)isLocked;

- (void)executionDidFinish;

- (NSArray *)history;
- (void)setHistory:(NSArray *)history;

@end

@interface NSObject (WBConsoleDelegate)

- (BOOL)console:(WBConsoleManager *)aConsole clickedOnLink:(id)link;
- (NSString *)console:(WBConsoleManager *)aConsole executeUserCommand:(NSString *)aCommand;

@end
