/*
 *  NSObject+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

@interface NSObject (WonderBox)

- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject;
- (void)performSelectorASAP:(SEL)aSelector withObject:(id)anObject inModes:(NSString *)aMode;

@end
