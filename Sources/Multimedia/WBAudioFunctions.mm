/*
 *  WBAudioFunctions.mm
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
#import WBHEADER(WBAudioFunctions.h)

void WBAudioStreamDescriptionInitializeLPCM(AudioStreamBasicDescription *outASBD, Float64 inSampleRate, UInt32 inChannelsPerFrame, 
                                            UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, bool inIsFloat,
                                            bool inIsBigEndian, bool inIsNonInterleaved) {
  bzero(outASBD, sizeof(*outASBD));
  FillOutASBDForLPCM(*outASBD, inSampleRate, inChannelsPerFrame, inValidBitsPerChannel, inTotalBitsPerChannel, inIsFloat, inIsBigEndian, inIsNonInterleaved);
}

void WBAudioTimeStampInitializeWithSampleTime(AudioTimeStamp *timeStamp, Float64 sample) {
  FillOutAudioTimeStampWithSampleTime(*timeStamp, sample);
}

void WBAudioTimeStampInitializeWithHostTime(AudioTimeStamp *timeStamp, UInt64 hostTime) {
  FillOutAudioTimeStampWithHostTime(*timeStamp, hostTime);
}

void WBAudioTimeStampInitializeWithSampleAndHostTime(AudioTimeStamp *timeStamp, Float64 sample, UInt64 hostTime) {
  FillOutAudioTimeStampWithSampleAndHostTime(*timeStamp, sample, hostTime);
}

// MARK: Channel Layout
UInt32 WBAudioChannelLayoutGetByteSize(const AudioChannelLayout *inLayout) {
  if (!inLayout) return 0;
  
	if (inLayout->mChannelLayoutTag == kAudioChannelLayoutTag_UseChannelDescriptions)
		return (UInt32)offsetof(AudioChannelLayout, mChannelDescriptions) + inLayout->mNumberChannelDescriptions * (UInt32)sizeof(AudioChannelDescription);
	
  return sizeof(AudioChannelLayout) - sizeof(AudioChannelDescription);
}


UInt32 WBAudioChannelLayoutGetNumberOfChannels(const AudioChannelLayout *inLayout) {
  if (!inLayout) return 0;
	if (inLayout->mChannelLayoutTag == kAudioChannelLayoutTag_UseChannelDescriptions)
		return inLayout->mNumberChannelDescriptions;
	
	if (inLayout->mChannelLayoutTag == kAudioChannelLayoutTag_UseChannelBitmap)
		return __builtin_popcount(inLayout->mChannelBitmap);
  
	return AudioChannelLayoutTag_GetNumberOfChannels(inLayout->mChannelLayoutTag);
}

