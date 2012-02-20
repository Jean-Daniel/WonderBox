/*
 *  WBTemplateParser.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBTemplateParser.h)

BOOL WBTemplateLogWarning = NO;
BOOL WBTemplateLogMessage = NO;

#define _WBTemplateLogWarning(msg, ...)				({ if (WBTemplateLogWarning) [self logWarning:msg ,##__VA_ARGS__]; })
#define _WBTemplateLogMessage(msg, indt, ...)		({ if (WBTemplateLogMessage) [self logMessage:msg indent:indt ,##__VA_ARGS__]; })

#pragma mark -
@implementation WBTemplateParser

- (id)init {
  return [self initWithFile:nil encoding:[NSString defaultCStringEncoding]];
}

- (id)initWithFile:(NSString *)aFile encoding:(NSStringEncoding)encoding {
  if (self = [super init]) {
    [self setFile:aFile];
    wb_encoding = encoding;
  }
  return self;
}

- (void)dealloc {
  [wb_file release];
  [super dealloc];
}

#pragma mark -
- (id)delegate {
  return wb_delegate;
}

- (void)setDelegate:(id)theDelegate {
  wb_delegate = theDelegate;
  if (wb_delegate) {
    tpimp.foundChars = [wb_delegate respondsToSelector:@selector(templateParser:foundCharacters:)] ? 1 : 0;
    tpimp.foundVar = [wb_delegate respondsToSelector:@selector(templateParser:foundVariable:)] ? 1 : 0;
    tpimp.startBlock = [wb_delegate respondsToSelector:@selector(templateParser:didStartBlock:)] ? 1 : 0;
    tpimp.endBlock = [wb_delegate respondsToSelector:@selector(templateParserDidEndBlock:)] ? 1 : 0;
    tpimp.startTemplate = [wb_delegate respondsToSelector:@selector(templateParser:didStartTemplate:)] ? 1 : 0;
    tpimp.endTemplate = [wb_delegate respondsToSelector:@selector(templateParser:didEndTemplate:)] ? 1 : 0;
    tpimp.warning  = [wb_delegate respondsToSelector:@selector(templateParser:warningOccured:)] ? 1 : 0;
  } else {
    bzero(&tpimp, sizeof(tpimp));
  }
}

- (NSString *)file {
  return wb_file;
}
- (void)setFile:(NSString *)aFile {
  WBSetterCopy(wb_file, aFile);
}

- (NSStringEncoding)encoding {
  return wb_encoding;
}
- (void)setStringEncoding:(NSStringEncoding)encoding {
  wb_encoding = encoding;
}

#pragma mark -
- (void)foundVariable:(CFStringRef)theVariable inString:(NSString *)theString atRange:(NSRange)aRange {
  if (tpimp.foundChars) {
    CFStringRef sub = CFStringCreateWithSubstring(kCFAllocatorDefault, WBNSToCFString(theString), CFRangeMake(wb_position, aRange.location - wb_position));
    if (sub) {
      [wb_delegate templateParser:self foundCharacters:WBCFToNSString(sub)];
      CFRelease(sub);
    }
  }
  wb_position = NSMaxRange(aRange);

  if (theVariable) {
    if (CFStringHasPrefix(theVariable, CFSTR("Start:"))) {
      CFIndex idx = [@"Start:" length];
      if (CFStringGetLength(theVariable) > idx) {
        CFStringRef var = CFStringCreateWithSubstring(kCFAllocatorDefault, theVariable, CFRangeMake(idx, CFStringGetLength(theVariable) - idx));
        if (var) {
          _WBTemplateLogMessage(@"Start Block: %@", wb_blocks, var);
          wb_blocks++;
          if (tpimp.startBlock)
            [wb_delegate templateParser:self didStartBlock:(id)var];
          CFRelease(var);
        }
      } else {
        _WBTemplateLogWarning(@"WARNING: Invalid Block: %@", theVariable);
        if (tpimp.warning)
          [wb_delegate templateParser:self warningOccured:[NSString stringWithFormat:@"Invalid Block: %@", theVariable]];
      }
    } else if (CFEqual(theVariable, CFSTR("End"))) {
      if (wb_blocks > 0) {
        wb_blocks--;
        _WBTemplateLogMessage(@"End Block", wb_blocks);
        if (tpimp.endBlock)
          [wb_delegate templateParserDidEndBlock:self];
      } else {
        _WBTemplateLogWarning(@"WARNING: @End tag encounter but all blocks already closed.");
        if (tpimp.warning)
          [wb_delegate templateParser:self warningOccured:@"@End tag encounter but all blocks already closed."];
      }
    } else {
      _WBTemplateLogMessage(@"Variable: %@", wb_blocks, theVariable);
      if (tpimp.foundVar)
        [wb_delegate templateParser:self foundVariable:(id)theVariable];
    }
  }
}

- (BOOL)parse {
  if (!wb_file)
		WBThrowException(NSInternalInconsistencyException, @"A file must be set before parsing.");

  wb_blocks = 0;
  wb_position = 0;

  CFStringRef str = NULL;

  str = (CFStringRef)[[NSString alloc] initWithContentsOfFile:wb_file encoding:wb_encoding error:nil];

  if (!str)
    return NO;

  CFStringInlineBuffer inlineBuffer;
  CFIndex length = CFStringGetLength(str);

  _WBTemplateLogMessage(@"Start File: %@", wb_blocks, wb_file);
  if (tpimp.startTemplate)
    [wb_delegate templateParser:self didStartTemplate:wb_file];

  CFMutableCharacterSetRef charSet = CFCharacterSetCreateMutableCopy(kCFAllocatorDefault,
                                                                     CFCharacterSetGetPredefined(kCFCharacterSetWhitespaceAndNewline));
  CFCharacterSetAddCharactersInString(charSet, CFSTR("!"));
  CFCharacterSetRef varEndChars = CFCharacterSetCreateCopy(kCFAllocatorDefault, charSet);
  CFRelease(charSet);

  CFStringInitInlineBuffer(str, &inlineBuffer, CFRangeMake(0, length));

  for (CFIndex cnt = 0; cnt < length; cnt++) {
    UniChar ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, cnt);
    if ('@' == ch) {
      CFRange space;
      if (CFStringFindCharacterFromSet(str, varEndChars, CFRangeMake(cnt, length - cnt), 0, &space)) {
        if (space.location != kCFNotFound) {
          ch = CFStringGetCharacterFromInlineBuffer(&inlineBuffer, space.location);
          if ('!' == ch) {
            cnt++;
            if (space.location > cnt) {
              CFStringRef var = CFStringCreateWithSubstring(kCFAllocatorDefault, str, CFRangeMake(cnt, space.location - cnt));
              if (var) {
                [self foundVariable:var inString:(id)str atRange:NSMakeRange(cnt -1, space.location - cnt + 2)];
                CFRelease(var);
              }
            }
            cnt = space.location;
          }
#if defined(DEBUG)
          else {
            if (space.location > cnt) {
              CFStringRef var = CFStringCreateWithSubstring(kCFAllocatorDefault, str, CFRangeMake(cnt, space.location - cnt));
              if (var) {
                NSLog(@"Ignore: %@", var);
                CFRelease(var);
              }
            }
          }
#endif
        }
      }
    }
  }
  /* Send characters between last var and end of file */
  [self foundVariable:nil inString:(id)str atRange:NSMakeRange([(NSString *)str length], 0)];
  CFRelease(varEndChars);
  [(id)str release];

  if (wb_blocks) {
    _WBTemplateLogWarning(@"WARNING: %u blocks unclosed.", wb_blocks);
    if (tpimp.warning)
      [wb_delegate templateParser:self warningOccured:[NSString stringWithFormat:@"%u blocks unclosed.", wb_blocks]];

    while (wb_blocks > 0) {
      if (tpimp.endBlock)
        [wb_delegate templateParserDidEndBlock:self];
      wb_blocks--;
    }
  }
  _WBTemplateLogMessage(@"End File: %@", wb_blocks, wb_file);
  if (tpimp.endTemplate)
    [wb_delegate templateParser:self didEndTemplate:wb_file];

  return YES;
}

#pragma mark -
#pragma mark Logging
- (void)_logString:(NSString *)msg isWarning:(BOOL)err args:(va_list)args {
  if (msg) {
    NSString *output = [[NSString alloc] initWithFormat:msg arguments:args];
    if (output) {
      fprintf(err ? stderr : stdout, "%s", [output UTF8String]);
      fprintf(err ? stderr : stdout, "\n");
      [output release];
    }
  }
}

- (void)logMessage:(NSString *)msg indent:(NSUInteger)indent, ... {
  va_list args;
  if (msg) {
    for (NSUInteger idx = 0; idx < indent; idx++) {
      fprintf(stdout, "\t");
    }
    va_start(args, indent);
    [self _logString:msg isWarning:NO args:args];
    va_end(args);
  }
}

- (void)logWarning:(NSString *)msg, ... {
  va_list args;
  if (msg) {
    va_start(args, msg);
    [self _logString:msg isWarning:YES args:args];
    va_end(args);
  }
}

@end
