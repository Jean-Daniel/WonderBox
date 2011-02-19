/*
 *  WBXMLTemplate.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBXMLTemplate.h)
#import WBHEADER(WBTemplateParser.h)

@implementation WBXMLTemplate


#pragma mark -
- (void)cleanOpenComment {
  NSUInteger idx = [wb_contents count] - 1;
  NSString *lastStr = [wb_contents objectAtIndex:idx];

  NSRange comment = [lastStr rangeOfString:@"<!--" options:NSBackwardsSearch | NSLiteralSearch];
  if (comment.location != NSNotFound) {
    comment.length = [lastStr length] - comment.location;
    lastStr = [lastStr substringToIndex:comment.location];
    [wb_contents replaceObjectAtIndex:idx withObject:lastStr];
  }
}

- (void)templateParser:(WBTemplateParser *)parser foundCharacters:(NSString *)aString {
  NSRange comment = NSMakeRange(NSNotFound, 0);
  if (wb_tplFlags.inBlock || ([self isBlock] && [wb_contents count] == 0)) {
    comment = [aString rangeOfString:@"-->" options:NSLiteralSearch];
    if (comment.location != NSNotFound) {
      comment.length = NSMaxRange(comment);
      comment.location = 0;
    }
  }
  [super templateParser:parser foundCharacters:(comment.location == NSNotFound) ? aString : [aString substringFromIndex:NSMaxRange(comment)]];
}

- (void)templateParser:(WBTemplateParser *)parser didStartBlock:(NSString *)blockName {
  [self cleanOpenComment];
  [super templateParser:parser didStartBlock:blockName];
}

- (void)templateParserDidEndBlock:(WBTemplateParser *)parser {
  [super templateParserDidEndBlock:parser];
  [self cleanOpenComment];
}


@end
