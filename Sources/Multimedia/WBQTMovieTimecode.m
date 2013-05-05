/*
 *  WBQTMovieTimecode.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__LP64__) || !__LP64__

#import <WonderBox/WBQTMovieTimecode.h>
#import <WonderBox/WBMediaFunctions.h>

#define   kCharacteristicHasVideoFrameRate 'vfrr'

@interface WBQTMovieTimecode ()
- (void)wb_didEditMovie:(NSNotification *)aNotification;
@end

@implementation WBQTMovieTimecode

static
Media _WBMovieGetTimecodeMedia(QTMovie *aMovie, BOOL *hasTimecode) {
  if (hasTimecode) *hasTimecode = NO;
  Movie qtMovie = [aMovie quickTimeMovie];

  Track tc = GetMovieIndTrackType(qtMovie, 1, TimeCode64MediaType, movieTrackMediaType | movieTrackEnabledOnly);
  if (!tc)
    tc = GetMovieIndTrackType(qtMovie, 1, TimeCodeMediaType, movieTrackMediaType | movieTrackEnabledOnly);
  if (tc && hasTimecode) *hasTimecode = YES;

  if (!tc)
    tc = GetMovieIndTrackType(qtMovie, 1, kCharacteristicHasVideoFrameRate, movieTrackCharacteristic | movieTrackEnabledOnly);
  if (!tc)
    tc = GetMovieIndTrackType(qtMovie, 1, VideoMediaType, movieTrackMediaType | movieTrackEnabledOnly);

  return tc ? GetTrackMedia(tc) : NULL;
}

- (id)initWithMovie:(QTMovie *)aMovie {
  if (self = [super init]) {
    BOOL hasTC;
    wb_qtmedia = _WBMovieGetTimecodeMedia(aMovie, &hasTC);
    if (!wb_qtmedia) {
      [self release];
      return nil;
    }

    wb_first = -1;
    wb_tcFlags.useTcTrack = 1;
    wb_movie = [aMovie retain];
    SPXFlagSet(wb_tcFlags.tcTrack, hasTC);
    wb_tcFlags.hdMode = kWBQTTimecodeMode24FPS;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wb_didEditMovie:)
                                                 name:QTMovieEditedNotification object:aMovie];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieEditedNotification object:nil];
  [wb_movie release];
  [super dealloc];
}

#pragma mark -
- (BOOL)usesTimeCodeTrack {
  return wb_tcFlags.useTcTrack;
}
- (void)setUsesTimeCodeTrack:(BOOL)flag {
  SPXFlagSet(wb_tcFlags.useTcTrack, flag);
  wb_first = -1;
}

- (double)staticFrameRate {
  if (wb_fps <= 0) WBQTMovieGetStaticFrameRate(wb_movie, &wb_fps);
  return wb_fps;
}
- (NSUInteger)numberOfFrame {
  if (wb_frames <= 0) {
    TimeValue64 duration = 0;
    TimeValue64 scale = GetMovieTimeScale([wb_movie quickTimeMovie]);
    OSStatus err = GetMoviesError();
    if (noErr == err) {
      duration = GetMovieDuration([wb_movie quickTimeMovie]);
      err = GetMoviesError();

      if (noErr == err)
        wb_frames = round([self staticFrameRate] * duration / scale);
    }
  }
  return wb_frames;
}

- (void)wb_didEditMovie:(NSNotification *)aNotification {
  wb_fps = -1;
  wb_first = -1;
  //WBTrace();
}

- (NSInteger)firstFrame {
  if (wb_first >= 0) return wb_first;

  if (wb_tcFlags.tcTrack && wb_tcFlags.useTcTrack) {
    Track track = GetMediaTrack(wb_qtmedia);
    MediaHandler mh = GetMediaHandler(wb_qtmedia);
    if (track && mh) {
      long frame;
      TimeValue start = TrackTimeToMediaTime(GetTrackOffset(track), track);
      TCGetTimeCodeAtTime(mh, start, &frame, NULL, NULL, NULL);
      wb_first = frame;
    }
  } else {
    Track track = GetMediaTrack(wb_qtmedia);
    if (track) {
      TimeValue start = GetTrackOffset(track);
      wb_first = -lround(start * [self staticFrameRate] / GetMediaTimeScale(wb_qtmedia));
    }
  }
  if (wb_first < 0) wb_first = 0;

  return wb_first;
}

- (NSInteger)frameForTime:(QTTime)aTime {
  if (QTTimeIsIndefinite(aTime)) return -1;

  long frame = 0;
  OSStatus err = -1;
  if (wb_tcFlags.tcTrack && wb_tcFlags.useTcTrack) {
    Track track = GetMediaTrack(wb_qtmedia);
    MediaHandler mh = GetMediaHandler(wb_qtmedia);
    if (track && mh) {
      err = TCGetTimeCodeAtTime(mh, TrackTimeToMediaTime(aTime.timeValue, track), &frame, NULL, NULL, NULL);
    }
    if (noErr == err)
      frame -= [self firstFrame];
  }
  if (noErr != err && aTime.timeScale) {
    frame = lround(aTime.timeValue * [self staticFrameRate] / aTime.timeScale);
  }
  return frame;
}
- (NSInteger)absoluteFrameForTime:(QTTime)aTime {
  return [self frameForTime:aTime] + [self firstFrame];
}

- (QTTime)timeForFrame:(NSInteger)aFrame {
  QTTime qtTime = QTIndefiniteTime;
//  if (wb_tcFlags.tcTrack) {
//    Track track = GetMediaTrack(wb_qtmedia);
//    MediaHandler mh = GetMediaHandler(wb_qtmedia);
//    if (track && mh) {
//      TimeCodeDef def;
//      TimeCodeRecord rec;
//      TCFrameNumberToTimeCode(mh, aFrame, &def, &rec);
//      qtTime = QTMakeTime(0, def.fTimeScale);
//    }
//  } else {
    qtTime = QTMakeTime(0, GetMediaTimeScale(wb_qtmedia));
    qtTime.timeValue = aFrame * qtTime.timeScale / [self staticFrameRate];
//  }
  return qtTime;
}
- (QTTime)timeForAbsoluteFrame:(NSInteger)aFrame {
  return [self timeForFrame:aFrame + [self firstFrame]];
}

- (NSString *)stringForTime:(QTTime)aTime {
  if (QTTimeIsIndefinite(aTime)) return @"--:--:--:--";
  NSString *str = nil;
  if (wb_qtmedia)
    // scale time to media time scale
    aTime = QTMakeTimeScaled(aTime, GetMediaTimeScale(wb_qtmedia));

  if (wb_tcFlags.tcTrack && wb_tcFlags.useTcTrack) {
    Track track = GetMediaTrack(wb_qtmedia);
    MediaHandler mh = GetMediaHandler(wb_qtmedia);
    if (track && mh) {
      TimeCodeDef tcdef;
      TimeCodeRecord tcrec;

      // Avoid warning when reaching end of movie.
      long duration = GetMediaDuration(wb_qtmedia);
      if (aTime.timeValue >= duration) aTime.timeValue = duration -1;

      if (noErr == TCGetTimeCodeAtTime(mh, TrackTimeToMediaTime(aTime.timeValue, track), NULL, &tcdef, &tcrec, NULL)) {
        Str255 pstring;
        if (noErr == TCTimeCodeToString(mh, &tcdef, &tcrec, pstring)) {
          if (pstring[1] == ' ') {
            str = [[NSString alloc] initWithBytes:pstring + 2 length:StrLength(pstring) - 1 encoding:NSMacOSRomanStringEncoding];
          } else {
            str = [[NSString alloc] initWithBytes:pstring + 1 length:StrLength(pstring) encoding:NSMacOSRomanStringEncoding];
          }
          [str autorelease];
        }
      } else {
        spx_debug("warning, fail to use timecode track: %d", GetMoviesError());
      }
    }
  }
  /* fall back to manual way */
  if (!str) {
    double rate = [self staticFrameRate];
    if (rate > 23.96 && rate < 23.98) {
      /* 23.98 */
      NSInteger frame;
      bool drop = true;
      switch (wb_tcFlags.hdMode) {
        default:
        case kWBQTTimecodeMode24FPS:
          drop = false;
          frame = [self frameForTime:aTime];
          break;
        case kWBQTTimecodeModeNTSC:
          rate = 30; // 30 drop frame
          frame = lround(aTime.timeValue * 29.97 / aTime.timeScale);
          frame -= [self firstFrame];
          /* adjust frame number */
        {
          NSInteger minutes = (frame / 29.97) / 60;
          frame +=  2 * (minutes - minutes / 10);
        }
          break;
        case kWBQTTimecodeModeDropFrame:
          rate = 24; // 24 drop frame
          frame = lround(aTime.timeValue * 23.97 / aTime.timeScale);
          frame -= [self firstFrame];
          /* adjust frame number */
        {
          NSInteger minutes = (frame / 23.97) / 60;
          frame +=  2 * (minutes - minutes / 10);
        }
          break;
      }

      NSUInteger seconds = frame / rate;

      NSInteger hours = seconds / 3600;
      seconds -= hours * 3600;

      NSInteger minutes = seconds / 60;
      seconds -= minutes * 60;

      NSInteger frames = lround(fmod(frame, rate));

      str = [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld%c%.2ld",
             (long)hours, (long)minutes, (long)seconds, drop ? ';' : ':', (long)frames];
    } else {
      if (fiszero(rate - floor(rate))) {
        /* integral rate */
        CGFloat frame = [self frameForTime:aTime];
        NSUInteger seconds = frame / rate;

        NSInteger hours = seconds / 3600;
        seconds -= hours * 3600;

        NSInteger minutes = seconds / 60;
        seconds -= minutes * 60;

        NSInteger frames = lround(fmod(frame, rate));

        str = [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld:%.2ld",
               (long)hours, (long)minutes, (long)seconds, (long)frames];
      } else {
        aTime.timeValue += round(([self firstFrame] * aTime.timeScale) / rate);
        str = QTStringFromTime(aTime);
      }
    }
  }
  return str;
}

@end

#endif /*LP64 */
