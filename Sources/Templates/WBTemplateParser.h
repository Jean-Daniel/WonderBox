/*
 *  WBTemplateParser.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Foundation/Foundation.h>

WB_OBJC_EXPORT
@interface WBTemplateParser : NSObject {
@private
  id wb_delegate;
  NSString *wb_file;
  NSUInteger wb_blocks;
  NSUInteger wb_position;
  NSStringEncoding wb_encoding;
  struct wb_tpimp {
    unsigned int foundChars:1;
    unsigned int foundVar:1;
    unsigned int startBlock:1;
    unsigned int endBlock:1;
    unsigned int startTemplate:1;
    unsigned int endTemplate:1;
    unsigned int warning:1;
    unsigned int:1;
  } tpimp;
}

- (id)initWithFile:(NSString *)aFile encoding:(NSStringEncoding)encoding;
- (BOOL)parse;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)file;
- (void)setFile:(NSString *)aFile;

- (NSStringEncoding)encoding;
- (void)setStringEncoding:(NSStringEncoding)encoding;

@end

extern BOOL WBTemplateLogWarning;
extern BOOL WBTemplateLogMessage;

@interface WBTemplateParser (Logging)

- (void)logMessage:(NSString *)msg indent:(NSUInteger)indent, ...;
- (void)logWarning:(NSString *)msg, ...;

@end

@interface NSObject (WBTemplateParserDelegate)

- (void)templateParser:(WBTemplateParser *)parser didStartTemplate:(NSString *)fileName;
- (void)templateParser:(WBTemplateParser *)parser didEndTemplate:(NSString *)fileName;

- (void)templateParser:(WBTemplateParser *)parser foundCharacters:(NSString *)aString;
- (void)templateParser:(WBTemplateParser *)parser foundVariable:(NSString *)variable;
- (void)templateParser:(WBTemplateParser *)parser didStartBlock:(NSString *)blockName;
- (void)templateParserDidEndBlock:(WBTemplateParser *)parser;

- (void)templateParser:(WBTemplateParser *)parser warningOccured:(NSString *)warning;

@end
