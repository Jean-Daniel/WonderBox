/*
 *  WBQTMovieTimecode.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBQTMovieTimecode.h)

#define   kCharacteristicIsAnMpegTrack     'mpeg'
#define   kCharacteristicHasVideoFrameRate 'vfrr'

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
  BOOL hasTC;
  wb_qtmedia = _WBMovieGetTimecodeMedia(aMovie, &hasTC);
  if (!wb_qtmedia) {
    [self release];
    self = nil;
  }
  if (self = [super init]) {
    wb_first = -1;
    wb_movie = [aMovie retain];
    WBFlagSet(wb_tcFlags.tcTrack, hasTC);
    wb_tcFlags.hdMode = kWBQTTimecodeModeNTSC;
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
- (double)staticFrameRate {
  if (wb_fps <= 0) WBQTMovieGetStaticFrameRate(wb_movie, &wb_fps);
  return wb_fps;
}
- (NSUInteger)numberOfFrame {
  if (wb_frames <= 0) {
    TimeValue64 duration;
    TimeValue64 scale = GetMovieTimeScale([wb_movie quickTimeMovie]);
    OSStatus err = GetMoviesError();
    if (noErr == err) {
      duration = GetMovieDuration([wb_movie quickTimeMovie]);
      err = GetMoviesError();
    }
    if (noErr == err) 
      wb_frames = round([self staticFrameRate] * duration / scale);
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
  
  if (wb_tcFlags.tcTrack) {
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
  if (wb_tcFlags.tcTrack) {
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
  if (wb_tcFlags.tcTrack) {
    Track track = GetMediaTrack(wb_qtmedia);
    MediaHandler mh = GetMediaHandler(wb_qtmedia);
    if (track && mh) {
      TimeCodeDef tcdef;
      TimeCodeRecord tcrec;
//      long duration = GetMediaDuration(wb_qtmedia);
//      if (aTime.timeValue >= duration) aTime.timeValue = duration -1;
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
        DCLog("warning, fail to use timecode track: %d", GetMoviesError());
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
             hours, minutes, seconds, drop ? ';' : ':', frames];
    } else {
      if (WBRealEquals(0, rate - floor(rate))) {
        /* integral rate */
        CGFloat frame = [self frameForTime:aTime];
        NSUInteger seconds = frame / rate;
        
        NSInteger hours = seconds / 3600;
        seconds -= hours * 3600;
        
        NSInteger minutes = seconds / 60;
        seconds -= minutes * 60;
        
        NSInteger frames = lround(fmod(frame, rate));
        
        str = [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld:%.2ld", 
               hours, minutes, seconds, frames];        
      } else {
        aTime.timeValue += round(([self firstFrame] * aTime.timeScale) / rate);
        str = QTStringFromTime(aTime);
      }
    }
  }
  return str;
}

@end

#pragma mark -
#pragma mark Static Frame rate

static
OSStatus _WBMediaHandlerIsMPEG(MediaHandler, Boolean *);
static
ComponentResult _WBMPEGMediaGetStaticFrameRate(MediaHandler inMPEGMediaHandler, Fixed *outStaticFrameRate);

static
OSStatus _WBMediaGetStaticFrameRate(Media, double *);
static
void _WBMovieGetVideoMediaAndMediaHandler(Movie, Media *, MediaHandler *);

/*
 Calculate the static frame rate for a given movie.
 */
void WBQTMovieGetStaticFrameRate(QTMovie *inMovie, double *outStaticFrameRate) {
  assert(inMovie != NULL);
  assert(outStaticFrameRate != NULL);
  
  *outStaticFrameRate = 0;
  
  Media movieMedia;
  MediaHandler movieMediaHandler;
  /* get the media identifier for the media that contains the first
   video track's sample data, and also get the media handler for
   this media. */
  _WBMovieGetVideoMediaAndMediaHandler([inMovie quickTimeMovie], &movieMedia, &movieMediaHandler);
  if (movieMedia && movieMediaHandler)
  {
    Boolean isMPEG = false;
    /* is this the MPEG-1/MPEG-2 media handler? */
    OSErr err = _WBMediaHandlerIsMPEG(movieMediaHandler, &isMPEG);
    if (err == noErr)
    {
      if (isMPEG) /* working with MPEG-1/MPEG-2 media */
      {
        Fixed staticFrameRate;
        err = _WBMPEGMediaGetStaticFrameRate(movieMediaHandler, &staticFrameRate);
        if (err == noErr)
        {
          /* convert Fixed data result to type double */
          *outStaticFrameRate = Fix2X(staticFrameRate);
        }
      }
      else  /* working with non-MPEG-1/MPEG-2 media */
      {
        err = _WBMediaGetStaticFrameRate(movieMedia, outStaticFrameRate);
        assert(err == noErr);
      }
    }
  }
}

/*
 Get the media identifier for the media that contains the first
 video track's sample data, and also get the media handler for
 this media.
 */
void _WBMovieGetVideoMediaAndMediaHandler(Movie inMovie, Media *outMedia, MediaHandler *outMediaHandler) {
  assert(inMovie != NULL);
  assert(outMedia != NULL);
  assert(outMediaHandler != NULL);
  
  *outMedia = NULL;
  *outMediaHandler = NULL;
  
  /* get first video track */
  Track videoTrack = GetMovieIndTrackType(inMovie, 1, kCharacteristicHasVideoFrameRate, movieTrackCharacteristic | movieTrackEnabledOnly);
  
  if (!videoTrack)
    videoTrack = GetMovieIndTrackType(inMovie, 1, VideoMediaType, movieTrackMediaType | movieTrackEnabledOnly);
  
  if (videoTrack != NULL) {
    /* get media ref. for track's sample data */
    *outMedia = GetTrackMedia(videoTrack);
    if (*outMedia) {
      /* get a reference to the media handler component */
      *outMediaHandler = GetMediaHandler(*outMedia);
    }
  }
}

/*
 Given a reference to the media that contains the sample data for a track,
 calculate the static frame rate.
 */
OSStatus _WBMediaGetStaticFrameRate(Media inMovieMedia, double *outFPS) {
  if (!outFPS || !inMovieMedia) return paramErr;
  
  *outFPS = 0;
  
  /* get the number of samples in the media */
  long sampleCount = GetMediaSampleCount(inMovieMedia);
  OSErr err = GetMoviesError();
  
  if (sampleCount && err == noErr)
  {
    /* find the media duration */
    TimeValue64 duration = GetMediaDisplayDuration(inMovieMedia);
    err = GetMoviesError();
    if (err == noErr)
    {
      /* get the media time scale */
      TimeValue64 timeScale = GetMediaTimeScale(inMovieMedia);
      err = GetMoviesError();
      if (err == noErr)
      {
        /* calculate the frame rate:
         frame rate = (sample count * media time scale) / media duration
         */
        *outFPS = (double)sampleCount * (double)timeScale / (double)duration;
      }
    }
  }
  
  return err;
}

/*
 Return true if media handler reference is from the MPEG-1/MPEG-2 media handler.
 Return false otherwise.
 */
OSStatus _WBMediaHandlerIsMPEG(MediaHandler inMediaHandler, Boolean *outIsMPEG) {
  assert(outIsMPEG != NULL);
  assert(inMediaHandler != NULL);
  
  /* is this the MPEG-1/MPEG-2 media handler? */
  return MediaHasCharacteristic(inMediaHandler, kCharacteristicIsAnMpegTrack, outIsMPEG);
}

/*
 Given a reference to the media handler used for media in a MPEG-1/MPEG-2
 track, return the static frame rate.
 */
ComponentResult _WBMPEGMediaGetStaticFrameRate(MediaHandler inMPEGMediaHandler, Fixed *outStaticFrameRate) {
  if (!inMPEGMediaHandler || !outStaticFrameRate) return paramErr;
  
  *outStaticFrameRate = 0;
  
  MHInfoEncodedFrameRateRecord encodedFrameRate;
  Size encodedFrameRateSize = sizeof(encodedFrameRate);
  
  /* get the static frame rate */
  ComponentResult err = MediaGetPublicInfo(inMPEGMediaHandler,
                                           kMHInfoEncodedFrameRate,
                                           &encodedFrameRate,
                                           &encodedFrameRateSize);
  if (err == noErr) {
    /* return frame rate at which the track was encoded */
    *outStaticFrameRate = encodedFrameRate.encodedFrameRate;
  }
  
  return err;
}

