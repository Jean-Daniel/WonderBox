/*
 *  WBAUFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

#import <Cocoa/Cocoa.h>
#import <AudioUnit/AudioUnit.h>

WB_EXPORT
NSView *WBAUInstanciateViewFromAudioUnit(AudioUnit anUnit, NSSize aSize);

//NSArray *WBAUInstanciateViewsFromAudioUnit(AudioUnit anUnit);
