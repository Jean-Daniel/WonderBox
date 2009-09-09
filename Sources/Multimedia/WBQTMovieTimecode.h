/*
 *  WBQTMovieTimecode.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <QTKit/QTKit.h>

#if !defined(__LP64__) || !__LP64__

enum {
  kWBQTTimecodeMode24FPS,
  kWBQTTimecodeModeNTSC, // 29.97 drop frame
  kWBQTTimecodeModeDropFrame, // 23.976 drop frame.
};

@interface WBQTMovieTimecode : NSObject {
@private
  QTMovie *wb_movie;
  
  struct _wb_tcFlags {
    unsigned int hdMode:2;
    unsigned int tcTrack:1;
    unsigned int useTcTrack:1;
    unsigned int reserved:4;
  } wb_tcFlags;
  /* cache */
  double wb_fps;
  Media wb_qtmedia;
  NSInteger wb_first;
  NSUInteger wb_frames;
}

- (id)initWithMovie:(QTMovie *)aMovie;

- (NSUInteger)numberOfFrame;

- (NSInteger)firstFrame;
- (NSInteger)frameForTime:(QTTime)aTime;
- (NSInteger)absoluteFrameForTime:(QTTime)aTime;

- (double)staticFrameRate;
- (NSString *)stringForTime:(QTTime)aTime;

- (QTTime)timeForFrame:(NSInteger)aFrame;
- (QTTime)timeForAbsoluteFrame:(NSInteger)aFrame;

- (BOOL)usesTimeCodeTrack;
- (void)setUsesTimeCodeTrack:(BOOL)flag;

@end

#endif /* LP64 */
