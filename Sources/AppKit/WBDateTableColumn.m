/*
 *  WBDateTableColumn.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBDateTableColumn.h)

@implementation WBDateTableColumn

#define WB_MEDIUM_DATE_WIDTH 80
#define WB_LONG_DATE_WIDTH 100

static
void _WBFixupDateFormat(NSDateFormatter *formatter, CGFloat width, CGFloat previous) {
  if (width < WB_MEDIUM_DATE_WIDTH) {
    if (previous >= WB_MEDIUM_DATE_WIDTH || previous < 0) {
      if ([formatter dateStyle] != NSDateFormatterNoStyle)
        [formatter setDateStyle:NSDateFormatterShortStyle];
    }
  } else if (width < WB_LONG_DATE_WIDTH) {
    if (previous < WB_MEDIUM_DATE_WIDTH || previous >= WB_LONG_DATE_WIDTH) {
      if ([formatter dateStyle] != NSDateFormatterNoStyle)
        [formatter setDateStyle:NSDateFormatterMediumStyle];
    }
  } else if (previous < WB_LONG_DATE_WIDTH) {
    if ([formatter dateStyle] != NSDateFormatterNoStyle)
      [formatter setDateStyle:NSDateFormatterLongStyle];
  }
}

- (void)awakeFromNib {
  _WBFixupDateFormat(ibDateFormat, [self width], -1);
}

- (void)setWidth:(CGFloat)newWidth {
  CGFloat previous = [self width];
  [super setWidth:newWidth];

  CGFloat width = [self width]; // setWidth: may adjust the value, so do not use newValue.
  _WBFixupDateFormat(ibDateFormat, width, previous);
}

@end
