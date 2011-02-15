/*
 *  WBConsoleManager.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBConsoleManager.h)

#import WBHEADER(WBObjCRuntime.h)
#import WBHEADER(NSCharacterSet+WonderBox.h)

@interface _WBConsoleTextView : NSTextView {
}

@end

@interface WBConsoleManager (InternalMethods) <NSTextViewDelegate>
- (void)execute;
- (NSString *)currentLine;
@end

#pragma mark -
@implementation WBConsoleManager

- (id)init {
  if (self = [super init]) {
    wb_historySize = 100;
    wb_queue = [[NSMutableString alloc] init];
    /* First history entry is current line */
    wb_history = [[NSMutableArray alloc] initWithObjects:@"", nil];
    wb_userColor = [[NSColor colorWithCalibratedRed:.165 green:.431 blue:1 alpha:1] retain];
    wb_systemColor = [[NSColor blackColor] retain];
  }
  return self;
}

- (void)dealloc {
  [self setTextView:nil];
  [wb_queue release];
  [wb_prompt release];
  [wb_history release];
  [wb_userColor release];
  [wb_systemColor release];
  [super dealloc];
}

#pragma mark -
- (NSFont *)font {
  return [wb_text font];
}
- (void)setFont:(NSFont *)aFont {
  [wb_text setFont:aFont];
}

- (NSTextView *)textView {
  return wb_text;
}
- (void)setTextView:(NSTextView *)aView {
  NSParameterAssert(aView == nil || [aView isMemberOfClass:[NSTextView class]]);
  if (wb_text != aView) {
    if (wb_text) {
      WBRuntimeSetObjectClass(wb_text, [NSTextView class]);
      [wb_text setDelegate:nil];
      [wb_text release];
    }
    wb_text = [aView retain];
    if (wb_text) {
      [wb_text setDelegate:self];
      [wb_text setTextColor:wb_userColor];
			WBRuntimeSetObjectClass(wb_text, [_WBConsoleTextView class]);
      if (wb_prompt) {
        [self appendSystemString:wb_prompt];
      }
    }
  }
}

/* Private method */
- (NSUInteger)appendString:(NSString *)aString hasNewLine:(BOOL *)newLine {
  NSUInteger length = 0;
  if (newLine) *newLine = NO;
  if ([aString length] > 0) {
    NSTextStorage *storage = [wb_text textStorage];
    // Search new line
    NSUInteger idx = [aString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location;
    // If contains new line
    if (idx != NSNotFound) {
      // WARNING: Do not handle windows new line.
      idx++;
      length = idx;
      if (newLine) *newLine = YES;
      [[storage mutableString] appendString:[aString substringToIndex:idx]];
    } else {
      length = [aString length];
      [[storage mutableString] appendString:aString];
    }
    // Change inserted text color
    NSRange range = NSMakeRange([storage length] - length, length);
    [wb_text setTextColor:wb_userColor range:range];
    [wb_text scrollRangeToVisible:range];
  }
  return length;
}

- (void)appendUserString:(NSString *)str {
  if (wb_cmFlags.lock || wb_cmFlags.disabled) {
    DLog(@"Cannot append string into a locked or disabled console");
    return;
  }
  /* Select end text */
  NSTextStorage *storage = [wb_text textStorage];
  [wb_text setSelectedRange:NSMakeRange([storage length], 0)];

  /* find end of line.
    -> append text before end of line to console.
    -> append remaining text into queue
    -> extract line and execute.
    */
  BOOL hasNewLine = NO;
  NSUInteger consumed = [self appendString:str hasNewLine:&hasNewLine];
  if (consumed > 0 && consumed < [str length]) {
    [wb_queue appendString:[str substringFromIndex:consumed]];
  }
  if (hasNewLine) {
    [self execute];
  }
}

- (NSRange)wb_appendSystemString:(NSString *)str color:(NSColor *)aColor {
  NSTextStorage *storage = [wb_text textStorage];
  [[storage mutableString] insertString:str atIndex:wb_uneditable];

  NSRange range = NSMakeRange(wb_uneditable, [str length]);
  [[wb_text textStorage] setAttributes:[wb_text typingAttributes] range:range];
  [[wb_text textStorage] addAttribute:NSForegroundColorAttributeName value:aColor ? : wb_systemColor range:range];
  [wb_text scrollRangeToVisible:NSMakeRange([storage length], 0)];

  wb_uneditable += [str length];
  return range;
}

- (void)appendSystemString:(NSString *)str {
  [self appendSystemString:str color:wb_systemColor];
}

- (void)appendSystemString:(NSString *)str color:(NSColor *)aColor {
  NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:aColor ? : wb_systemColor, NSForegroundColorAttributeName, nil];
  [self appendSystemString:str attributes:attr];
  [attr release];
}

- (void)appendSystemFormat:(NSString *)format color:(NSColor *)aColor, ... {
  va_list args;
  NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:aColor ? : wb_systemColor, NSForegroundColorAttributeName, nil];
  va_start(args, aColor);
  [self appendSystemFormat:format attributes:attr arguments:args];
  va_end(args);
  [attr release];
}

- (void)appendSystemString:(NSString *)str link:(id)aLink {
  NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:aLink, NSLinkAttributeName, nil];
  [self appendSystemString:str attributes:attr];
  [attr release];
}

- (void)appendSystemFormat:(NSString *)format link:(id)aLink, ... {
  va_list args;
  NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:aLink, NSLinkAttributeName, nil];
  va_start(args, aLink);
  [self appendSystemFormat:format attributes:attr arguments:args];
  va_end(args);
  [attr release];
}

- (void)appendSystemString:(NSString *)str attributes:(NSDictionary *)attributes {
  id attrs = [wb_text typingAttributes];
  NSTextStorage *storage = [wb_text textStorage];
  [storage beginEditing];
  [[storage mutableString] insertString:str atIndex:wb_uneditable];

  NSRange range = NSMakeRange(wb_uneditable, [str length]);
  /* Set default attributes */
  [[wb_text textStorage] setAttributes:attrs range:range];
  /* Add custom ones */
  [[wb_text textStorage] addAttributes:attributes range:range];
  [[wb_text textStorage] setAttributes:attrs range:NSMakeRange([storage length], 0)];
  [storage endEditing];

  wb_uneditable += [str length];
  [wb_text setTypingAttributes:attrs];
  [wb_text scrollRangeToVisible:NSMakeRange([storage length], 0)];
}

- (void)appendSystemFormat:(NSString *)format attributes:(NSDictionary *)attributes, ... {
  va_list args;
  va_start(args, attributes);
  [self appendSystemFormat:format attributes:attributes arguments:args];
  va_end(args);
}

- (void)appendSystemFormat:(NSString *)format attributes:(NSDictionary *)attributes arguments:(va_list)args {
  NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
  if (str) {
    [self appendSystemString:str attributes:attributes];
    [str release];
  }
}

- (IBAction)clear:(id)sender {
  /* If not executing and not locked */
  if (!wb_cmFlags.execute && ![self isLocked]) {
    /* Delete all but last line */
    NSUInteger start;
    NSMutableString *contents = [[wb_text textStorage] mutableString];
    [[wb_text string] getLineStart:&start
                               end:NULL
                       contentsEnd:NULL
                          forRange:NSMakeRange([contents length], 0)];
    /* Adjust uneditable mark */
    wb_uneditable -= start;
    [contents deleteCharactersInRange:NSMakeRange(0, start)];
  } else {
    /* Delete all */
    wb_uneditable = 0;
    [wb_text setString:@""];
  }
}

- (NSString *)prompt {
  return wb_prompt;
}
- (void)setPrompt:(NSString *)aString {
  if (aString != wb_prompt) {
    [wb_prompt release];
    wb_prompt = [aString copy];
  }
}
- (IBAction)prompt:(id)sender {
  if (wb_prompt) {
    [self appendSystemString:wb_prompt];
  }
}

- (id)delegate {
  return wb_delegate;
}
- (void)setDelegate:(id)delegate {
  wb_delegate = delegate;
}

- (BOOL)isEnabled {
  return !wb_cmFlags.disabled;
}
- (void)setEnabled:(BOOL)flag {
  WBFlagSet(wb_cmFlags.disabled, !flag);
}

- (BOOL)isLocked {
  return wb_cmFlags.lock;
}
- (void)lock {
  if (wb_cmFlags.execute && !wb_cmFlags.lock) {
    wb_cmFlags.lock = 1;
  } else {
		WBThrowException(NSInternalInconsistencyException, @"Trying to lock a console that is not executing a command or already locked.");
  }
}
- (void)unlock {
  if (wb_cmFlags.execute && wb_cmFlags.lock) {
    wb_cmFlags.lock = 0;
    wb_cmFlags.execute = 0;
    [self executionDidFinish];
  } else {
    DLog(@"Trying to unlock a console that is not executing a command or already unlocked.");
		//WBThrowException(NSInternalInconsistencyException, @"Trying to unlock a console that is not executing a command or already unlocked.");
  }
}

- (NSArray *)history {
  if ([wb_history count] > 1)
    return [wb_history subarrayWithRange:NSMakeRange(1, [wb_history count] - 1)];
  return nil;
}

- (void)setHistory:(NSArray *)history {
  NSString *current = nil;
  if ([wb_history count] >= 1) {
    current = [[wb_history objectAtIndex:0] retain];
  }
  [wb_history removeAllObjects];
  if (current) {
    [wb_history addObject:current];
    [current release];
  }
  if (history)
    [wb_history addObjectsFromArray:history];
}

#pragma mark -
#pragma mark Internal Methods
- (IBAction)stop:(id)sender {
  WBTrace();
}
- (IBAction)exit:(id)sender {
  WBTrace();
}

- (NSString *)currentLine {
  NSString *string = [wb_text string];
  NSRange editable = NSMakeRange(wb_uneditable, ([string length]) - wb_uneditable);
  return [string substringWithRange:editable];
}

- (void)insertHistoryLine {
  NSString *line = [wb_history objectAtIndex:wb_historyLine];
  NSMutableString *string = [[wb_text textStorage] mutableString];
  NSRange editable = NSMakeRange(wb_uneditable, ([string length]) - wb_uneditable);

  [string replaceCharactersInRange:editable withString:[wb_history objectAtIndex:wb_historyLine]];
  [wb_text setTextColor:wb_userColor range:NSMakeRange(wb_uneditable, [line length])];
}

- (IBAction)historyNext:(id)sender {
  if (wb_cmFlags.lock || wb_cmFlags.disabled) {
    NSBeep();
    return;
  }
  if (wb_historyLine > 0) {
    wb_historyLine--;
    [self insertHistoryLine];
  } else {
    NSBeep();
  }
}

- (IBAction)historyPrevious:(id)sender {
  if (wb_cmFlags.lock || wb_cmFlags.disabled) {
    NSBeep();
    return;
  }
  if (wb_historyLine < [wb_history count] -1) {
    if (wb_historyLine == 0) {
      [wb_history replaceObjectAtIndex:0 withObject:[self currentLine]];
    }
    wb_historyLine++;
    [self insertHistoryLine];
  } else {
    NSBeep();
  }
}

- (NSString *)wb_execute:(NSString *)cmd {
  wb_cmFlags.execute = 1;
  wb_uneditable = [[wb_text textStorage] length];

  /* === Delegate === */
  if (WBDelegateHandle(wb_delegate, console:executeUserCommand:)) {
    cmd = [wb_delegate console:self executeUserCommand:cmd];
  }
  if (![self isLocked]) {
    wb_cmFlags.execute = 0;
    [self executionDidFinish];
  }
  return cmd;
}

- (NSString *)lastCommand {
  return [wb_history count] > 1 ? [wb_history objectAtIndex:1] : nil;
}

- (void)execute {
  if ([self isLocked]) {
		WBThrowException(NSInternalInconsistencyException, @"Request line execution in a locked console.");
  }
  NSString *storage = [[wb_text textStorage] string];
  // WARNING: does not handle Windows new line
  NSString *line = [storage substringWithRange:NSMakeRange(wb_uneditable, ([storage length] - 1) - wb_uneditable)];

  if ((line = [self wb_execute:line])) {
    /* === History === */
    if ([wb_history count] == wb_historySize) {
      [wb_history removeLastObject];
    }
    [wb_history insertObject:line atIndex:1];
    wb_historyLine = 0;
  }
}

- (void)executionDidFinish {
  if (wb_prompt)
    [self appendSystemString:wb_prompt];
  BOOL newLine = NO;
  NSUInteger length = [self appendString:wb_queue hasNewLine:&newLine];
  if (length > 0) {
    [wb_queue deleteCharactersInRange:NSMakeRange(0, length)];
  }
  if (newLine) {
    [self execute];
  }
}

#pragma mark -
#pragma mark TextView Delegate Methods
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
  if (wb_cmFlags.lock || wb_cmFlags.disabled) {
    NSBeep();
    return NO;
  }
  /* If uneditable part is selected: handle it manually and return NO */
  if (wb_uneditable > affectedCharRange.location) {
    if ([replacementString length] > 0) {
      [self appendUserString:replacementString];
    } else {
      /* Remove editables selected characters */
      if (NSMaxRange(affectedCharRange) > wb_uneditable) {
        affectedCharRange.length = NSMaxRange(affectedCharRange) - wb_uneditable;
        affectedCharRange.location = wb_uneditable;
        [[wb_text textStorage] deleteCharactersInRange:affectedCharRange];
      }
    }
    return NO;
  } else if ([replacementString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
    [self appendUserString:replacementString];
    return NO;
  }
  return YES;
}

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)aLink atIndex:(NSUInteger)charIndex {
  if (WBDelegateHandle(wb_delegate, console:clickedOnLink:)) {
    return [wb_delegate console:self clickedOnLink:aLink];
  }
  return NO;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
  if (wb_uneditable <= [wb_text rangeForUserTextChange].location) {
    if (aSelector == @selector(moveDown:)) {
      [self historyNext:nil];
      return YES;
    } else if (aSelector == @selector(moveUp:)) {
      [self historyPrevious:nil];
      return YES;
    }
    /* Maybe handle tab too to add completion */
    //    else if (aSelector == @selector(insertTab:)) {
    //      if (wb_delegate && [wb_delegate respondsToSelector:@selector(handleTab:)]) {
    //        return [wb_delegate handleTab:self];
    //      }
    //      return NO;
    //}
    else {
      /* Should handle move to beginning to go to wb_uneditable */
    }
  }
  return NO;
}

@end

#pragma mark -
#pragma mark KeyBinding Overrloading
@implementation _WBConsoleTextView

- (BOOL)interpretKeyEvent:(NSEvent *)theEvent {
  if (([theEvent modifierFlags] & 0xffff0000U) == NSControlKeyMask) {
    NSString *chars = [theEvent charactersIgnoringModifiers];
    if ([chars length] == 1) {
      switch ([chars characterAtIndex:0]) {
        case 'c':
          [[self delegate] stop:nil];
          return YES;
        case 'd':
          [[self delegate] exit:nil];
          return YES;
        default:
          break;
      }
    }
  }
  return NO;
}

- (void)interpretKeyEvents:(NSArray *)eventArray {
  if ([eventArray count] == 1) {
    if (![self interpretKeyEvent:[eventArray objectAtIndex:0]])
      [super interpretKeyEvents:eventArray];
  } else {
    NSUInteger idx = 0, count = [eventArray count];
    while (idx < count) {
      NSEvent *theEvent = [eventArray objectAtIndex:idx];
      if (![self interpretKeyEvent:theEvent])
        [super interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
      idx++;
    }
  }
}

@end
