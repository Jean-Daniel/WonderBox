/*
 *  WBDateTableColumn.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

WB_OBJC_EXPORT
@interface WBDateTableColumn : NSTableColumn {
@private
  IBOutlet NSDateFormatter *ibDateFormat;
}

@end
