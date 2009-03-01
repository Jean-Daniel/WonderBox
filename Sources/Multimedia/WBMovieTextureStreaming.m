/*
 *  WBMovieTextureStreaming.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBMovieTextureInternal.h)
#import WBHEADER(WBQTVisualContext.h)

#if !__LP64__
static
OSStatus _WBQDMakeQTGWorld(Rect *bounds, bool clear, GWorldPtr *gworld) {
  OSErr err = noErr;
	GWorldPtr newGWorld = NULL;
  
	err = QTNewGWorld(&newGWorld, 0, bounds, NULL, NULL, kNativeEndianPixMap);
  
	if (err == noErr) {
    if (clear && LockPixels(GetGWorldPixMap(newGWorld))) {
      Rect portRect;
      GWorldPtr savedPort;
      GDHandle savedDevice;
      RGBColor theBlackColor = { 0, 0, 0 };
      RGBColor theWhiteColor = { 65535, 65535, 65535 };
      
      GetGWorld(&savedPort, &savedDevice);
      SetGWorld(newGWorld, NULL);
      
      GetPortBounds(newGWorld, &portRect);
      RGBBackColor(&theBlackColor);
      RGBForeColor(&theWhiteColor);
      EraseRect(&portRect);
      
      /* restore gworld */
      SetGWorld(savedPort, savedDevice);
      
      UnlockPixels(GetGWorldPixMap(newGWorld));  
    }
    *gworld = newGWorld;
  }
  
  return err;  
}

#pragma mark -
@implementation WBStreamingMovie (_WBCarbonImplementation)
/* GWorld Code Path */
static 
void _WBQTICMDecompressionTrackingCallback(void *decompressionTrackingRefCon, OSStatus result, 
                                           ICMDecompressionTrackingFlags flags, CVPixelBufferRef pixelBuffer, 
                                           TimeValue64 displayTime, TimeValue64 displayDuration, ICMValidTimeFlags validTimeFlags, 
                                           void *reserved, void *sourceFrameRefCon) {
  //  if ((flags & kICMDecompressionTracking_EmittingFrame) && pixelBuffer) {
  //    
  //  }
  if (flags & kICMDecompressionTracking_ReleaseSourceData) {
    // release buffer.
    if (sourceFrameRefCon) CVBufferRelease(sourceFrameRefCon);
  }
}

static 
OSErr _WBMovieDrawingCompleteProcPtr(Movie theMovie, long refCon) {
  Rect bounds;
  TimeRecord rec;
  GWorldPtr gworld;
  PixMapHandle pixmap;
  GetMovieTime(theMovie, &rec);
  Fixed rate = GetMovieRate(theMovie);
  WBStreamingMovie *self = (WBStreamingMovie *)refCon;
  
  ICMDecompressionSessionRef session = ICMDecompressionSessionRetain(self->wb_icmSession);
  if (!session) return noErr;
  
  GetMovieGWorld(theMovie, &gworld, NULL);
  pixmap = GetGWorldPixMap(gworld);
  GetPortBounds(gworld, &bounds);  
  
  if (LockPixels(pixmap)) {
    /* prepare time record */
    ICMFrameTimeRecord now;
    bzero(&now, sizeof(now));
    now.recordSize = sizeof(now);
    
    now.rate = rate;
    now.frameNumber = 0;
    now.value = rec.value;
    now.scale = rec.scale;
    now.base = rate ? GetMovieTimeBase(theMovie) : NULL;
    now.flags = rate ? 0 : icmFrameTimeIsNonScheduledDisplayTime;
    
    const UInt8 *data = (const UInt8 *)GetPixBaseAddr(pixmap);
    ByteCount length = GetPixRowBytes(pixmap) * (bounds.bottom - bounds.top);
    
    CVPixelBufferRef buffer = NULL;
    if (rate) {
      /* In fact, we have to copy the buffer because the decompress session expect that the memory not change until
       kICMDecompressionTracking_ReleaseSourceData is call, and the GWorld pixmap may change.
       Usually, it will not allocate more than one or two buffer. */
      verify_noerr(CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self->wb_pool, &buffer));
      if (noErr == CVPixelBufferLockBaseAddress(buffer, 0)) {
        memcpy(CVPixelBufferGetBaseAddress(buffer), data, length);
        data = CVPixelBufferGetBaseAddress(buffer);
        CVPixelBufferUnlockBaseAddress(buffer, 0);
      }
    } 
    verify_noerr(ICMDecompressionSessionDecodeFrame(session, data, length, NULL, &now, buffer));
    /* Force frame out */
    if (!rate) {
      verify_noerr(ICMDecompressionSessionSetNonScheduledDisplayTime(session, WideToSInt64(now.value), now.scale, 0));
    }
    UnlockPixels(pixmap);
  }
  ICMDecompressionSessionRelease(session);
  return noErr;
}

- (void)wbs_updateDecompressionSession:(QTMovie *)aMovie {
  if (wb_icmSession) {
    ICMDecompressionSessionRef previous = wb_icmSession;
    wb_icmSession = NULL;
    ICMDecompressionSessionFlush(previous);
    ICMDecompressionSessionRelease(previous);
  }
  if (aMovie && [self visualContext]) {
    GWorldPtr srcGWorld = NULL;
    GetMovieGWorld([aMovie quickTimeMovie], &srcGWorld, NULL);
    verify_noerr(GetMoviesError());
    if (srcGWorld) {
      Rect rect;
      GetMovieBox([aMovie quickTimeMovie], &rect);
      PixMapHandle hPixMap = GetGWorldPixMap(srcGWorld);
      ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
      verify_noerr(MakeImageDescriptionForPixMap(hPixMap, &imageDesc));
      
      ICMDecompressionTrackingCallbackRecord cb = { _WBQTICMDecompressionTrackingCallback , self };
      verify_noerr(ICMDecompressionSessionCreateForVisualContext(kCFAllocatorDefault, imageDesc, NULL, 
                                                                 [[self visualContext] quickTimeContext], &cb, (ICMDecompressionSessionRef *)&wb_icmSession));
      DisposeHandle((Handle)imageDesc);
    }
  }
}

- (void)wbs_updateStreamingContext:(QTMovie *)aMovie {
  [self wbs_updateDecompressionSession:aMovie];
  if (wb_pool) {
    CVPixelBufferPoolRef previous = wb_pool;
    wb_pool = NULL;
    CVPixelBufferPoolRelease(previous);
  }
  
  if (aMovie) {
    GWorldPtr srcGWorld = NULL;
    GetMovieGWorld([aMovie quickTimeMovie], &srcGWorld, NULL);
    verify_noerr(GetMoviesError());
    if (srcGWorld) {
      Rect rect;
      GetPortBounds(srcGWorld, &rect);
      PixMapHandle hPixMap = GetGWorldPixMap(srcGWorld);
      
      CFNumberRef value;
      CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
                                                               &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
      
      SInt32 integer = GETPIXMAPPIXELFORMAT(*hPixMap);
      value = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &integer);
      CFDictionarySetValue(attrs, kCVPixelBufferPixelFormatTypeKey, value);
      CFRelease(value);
      
      /* we don't really care about the image structure. we just uses the buffer pool to store raw data */
      /* so we make sure this buffer will be large enough to store the pixmap */
      integer = ceil(GetPixRowBytes(hPixMap) / 4.0); //ABS(rect.right - rect.left);
      value = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &integer);
      CFDictionarySetValue(attrs, kCVPixelBufferWidthKey, value);
      CFRelease(value);
      
      integer = ABS(rect.top - rect.bottom);
      value = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &integer);
      CFDictionarySetValue(attrs, kCVPixelBufferHeightKey, value);
      CFRelease(value);
      
      //      integer = 16; //GetPixRowBytes(hPixMap);
      //      value = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &integer);
      //      CFDictionarySetValue(attrs, kCVPixelBufferBytesPerRowAlignmentKey, value);
      //      CFRelease(value);
      
      verify_noerr(CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, attrs, &wb_pool));
      CFRelease(attrs);
    }
  }
}

- (void)configureMovie:(QTMovie *)aMovie {
  [super configureMovie:aMovie];
  SetMoviePlayHints([aMovie quickTimeMovie], hintsAllowDynamicResize, hintsAllowDynamicResize);
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_movieSizeDidChange:) name:QTMovieSizeDidChangeNotification object:aMovie];
  
  Rect rect;
  GWorldPtr srcGWorld = NULL;
  GetMovieBox([aMovie quickTimeMovie], &rect);
  /* make offscreen gworld to draw movie frames into */
  verify_noerr(_WBQDMakeQTGWorld(&rect, false, &srcGWorld));
  /* set the graphics world for displaying the movie */
  SetMovieGWorld([aMovie quickTimeMovie], srcGWorld, NULL);
  
  SetMovieDrawingCompleteProc([aMovie quickTimeMovie], movieDrawingCallWhenChanged, _WBMovieDrawingCompleteProcPtr, (long)self);
  
  [self wbs_updateStreamingContext:aMovie]; 
}

/* unregister notification and cleanup session & pool */
- (void)cleanupMovie:(QTMovie *)aMovie {
  [super cleanupMovie:aMovie];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieSizeDidChangeNotification object:aMovie];
  
  SetMovieDrawingCompleteProc([aMovie quickTimeMovie], movieDrawingCallWhenChanged, NULL, 0);
  SetMovieGWorld([aMovie quickTimeMovie], NULL, NULL);
  
  [self wbs_updateStreamingContext:nil];
}

- (void)setVisualContext:(WBQTVisualContext *)ctxt {
  [super setVisualContext:ctxt];
  [self wbs_updateDecompressionSession:[self movie]];
}

#pragma mark Notifications
- (void)_movieSizeDidChange:(NSNotification *)aNotification {
  Movie myMovie = [[aNotification object] quickTimeMovie];
  
  Rect bounds;
  GWorldPtr srcGWorld;
  GetMovieBox(myMovie, &bounds);
  verify_noerr(_WBQDMakeQTGWorld(&bounds, false, &srcGWorld));
  SetMovieGWorld(myMovie, srcGWorld, NULL);
  
  [self wbs_updateStreamingContext:[aNotification object]];
}

@end

#endif
