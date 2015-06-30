/*
 *  NSInvocation+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Foundation/Foundation.h>

@interface NSInvocation (WBExtensions)

+ (id)invocationWithTarget:(id)target selector:(SEL)action;

@end
