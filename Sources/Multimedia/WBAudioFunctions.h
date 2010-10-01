/*
 *  WBAudioFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <CoreAudio/CoreAudio.h>

#if !defined(__WB_AUDIO_FUNCTIONS_H)
#define __WB_AUDIO_FUNCTIONS_H 1

#include WBHEADER(WBBase.h)

WB_EXPORT
void WBAudioStreamDescriptionInitializeLPCM(AudioStreamBasicDescription *outASBD, Float64 inSampleRate, UInt32 inChannelsPerFrame,
                                            UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, bool inIsFloat,
                                            bool inIsBigEndian, bool inIsNonInterleaved);

WB_EXPORT
void WBAudioTimeStampInitializeWithHostTime(AudioTimeStamp *timeStamp, UInt64 hostTime);

WB_EXPORT
void WBAudioTimeStampInitializeWithSampleTime(AudioTimeStamp *timeStamp, Float64 sample);

WB_EXPORT
void WBAudioTimeStampInitializeWithSampleAndHostTime(AudioTimeStamp *timeStamp, Float64 sample, UInt64 hostTime);

// MARK: Channel Layout
WB_EXPORT
UInt32 WBAudioChannelLayoutGetByteSize(const AudioChannelLayout *inLayout);
WB_EXPORT
UInt32 WBAudioChannelLayoutGetNumberOfChannels(const AudioChannelLayout *inLayout);

#endif /* __WB_AUDIO_FUNCTIONS_H */
