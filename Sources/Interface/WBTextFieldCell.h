/*
 *  WBTextFieldCell.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

WB_CLASS_EXPORT
@interface WBTextFieldCell : NSTextFieldCell <NSCopying, NSCoding> {
@private
  struct {
    unsigned int line:1;
    unsigned int middle:1;
    unsigned int reserved:30;
  } wb_tfFlags;  
}

+ (id)cell;

- (BOOL)drawsLineOver;
- (void)setDrawsLineOver:(BOOL)flag;

- (BOOL)centersVertically;
- (void)setCentersVertically:(BOOL)flag;

@end