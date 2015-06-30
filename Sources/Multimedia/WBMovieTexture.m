/*
 *  WBMovieTexture.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !__LP64__
#import WBHEADER(WBMovieTexture.h)

#import WBHEADER(WBClassCluster.h)

#import WBHEADER(WBMediaFunctions.h)
#import WBHEADER(WBQTVisualContext.h)

#import "WBMovieTextureInternal.h"

@interface WBFileMovie : WBMovieTexture {
@private
  QTVisualContextRef wb_backup;
}

@end

WBClassCluster(WBMovieTexture)

@implementation WBClusterPlaceholder(WBMovieTexture) (WBMovieStreaming)

- (id)initWithMovie:(QTMovie *)aMovie {
  NSArray *streams = [aMovie tracksOfMediaType:QTMediaTypeStream];
  if ([streams count] == 0) {
    return [[WBFileMovie alloc] initWithMovie:aMovie];
  } else if (NSClassFromString(@"WBStreamingMovie")) {
    return [[NSClassFromString(@"WBStreamingMovie") alloc] initWithMovie:aMovie];
  }
  return nil;
}

@end


@implementation WBMovieTexture

- (id)initWithMovie:(QTMovie *)aMovie {
  if (self = [super init]) {
    [self setMovie:aMovie];
  }
  return self;
}

- (void)dealloc {
  [self dispose];
  [wb_movie release];
  [super dealloc];
}

#pragma mark -
- (QTMovie *)movie {
  return wb_movie;
}

- (void)dispose {
  [self setCurrentFrame:NULL];
  [self setVisualContext:nil];
  [self setMovie:nil];
  [self unlock];
}

#pragma mark -
static volatile OSSpinLock sWBFrameLock = OS_SPINLOCK_INIT;
- (void)setCurrentFrame:(CVImageBufferRef)aFrame {
  OSSpinLockLock(&sWBFrameLock);
  if (aFrame == wb_frame) { OSSpinLockUnlock(&sWBFrameLock); return; }
  wb_mtFlag.time = 0;
  if (wb_frame) CVBufferRelease(wb_frame);
  wb_frame = aFrame ? CVBufferRetain(aFrame) : NULL;
  OSSpinLockUnlock(&sWBFrameLock);
}

- (void)lock {
  NSParameterAssert(NULL == wb_locked);
  OSSpinLockLock(&sWBFrameLock);
  wb_locked = CVBufferRetain(wb_frame);
  wb_mtFlag.ltime = wb_mtFlag.time;
  OSSpinLockUnlock(&sWBFrameLock);
}
- (QTTime)currentTime {
  if (!wb_mtFlag.ltime) {
    wb_mtFlag.ltime = 1;
    wb_time = wb_locked ? WBCVBufferGetMovieTime(wb_locked) : QTIndefiniteTime;
  }
  return wb_time;
}
- (CVOpenGLTextureRef)currentFrame {
  return wb_locked;
}
- (void)unlock {
  OSSpinLockLock(&sWBFrameLock);
  CVBufferRelease(wb_locked);
  wb_mtFlag.ltime = 0;
  wb_locked = NULL;
  OSSpinLockUnlock(&sWBFrameLock);
}

- (CVOpenGLTextureRef)copyCurrentFrame {
  OSSpinLockLock(&sWBFrameLock);
  CVOpenGLTextureRef frame = wb_frame;
  if (frame) CVOpenGLTextureRetain(frame);
  OSSpinLockUnlock(&sWBFrameLock);
  return frame;
}

#pragma mark ===============
- (void)reclaimResources {
  [wb_context reclaimResources];
}

- (BOOL)update:(const CVTimeStamp *)aTimestamp {
  WBQTVisualContext *qtctxt = [wb_context retain];
  // See if a new frame is available
  if (qtctxt && [qtctxt isNewImageAvailableForTime:aTimestamp]) {
    OSStatus error = noErr;
    CVImageBufferRef frame = [qtctxt copyImageForTime:aTimestamp allocator:kCFAllocatorDefault error:&error];

    // In general this shouldn't happen, but just in case...
    if(error == noErr && frame) {
      [self setCurrentFrame:frame];
      CVBufferRelease(frame);
      [qtctxt release];
      return YES;
    } else {
      SPXLogWarning(@"QTVisualContextCopyImageForTime: %s (%d)\n", GetMacOSStatusErrorString(error), error);
    }
  }
  [qtctxt release];
  return NO;
}

/* active mode support */
- (void)setOpenGLContext:(CGLContextObj)aContext format:(CGLPixelFormatObj)aFormat {
  [self setCurrentFrame:NULL];
  [self setVisualContext:nil];
  if (!aContext || !aFormat) return;

  // creates a new OpenGL texture context for a specified OpenGL context and pixel format (with default attributes)
  WBQTVisualContext *ctxt = [[WBQTVisualContext alloc] initWithOpenGLContext:aContext pixelFormat:aFormat attributes:nil];
  if ([self shouldNotifyDrawer]) [ctxt setDelegate:self];
  [self setVisualContext:ctxt];
  [ctxt release];
}

- (WBQTVisualContext *)visualContext {
  return wb_context;
}
- (void)setVisualContext:(WBQTVisualContext *)ctxt {
  SPXSetterRetain(wb_context, ctxt);
}

- (void)configureMovie:(QTMovie *)aMovie {}
- (void)cleanupMovie:(QTMovie *)aMovie {}

- (void)setMovie:(QTMovie *)aMovie {
  if (aMovie == [self movie]) return;
  if (wb_movie) {
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:QTMovieRateDidChangeNotification object:wb_movie];
    [wb_movie stop]; // make sure the movie is stopped

    [self cleanupMovie:wb_movie];

    [wb_movie release];
  }
  wb_movie = [aMovie retain];
  if (wb_movie) {
    CGFloat rate = [wb_movie rate];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wb_movieRateDidChange:) name:QTMovieRateDidChangeNotification object:wb_movie];
    SetMoviePlayHints([wb_movie quickTimeMovie], hintsHighQuality, hintsHighQuality);

    [self configureMovie:wb_movie];
    if (fiszero(rate)) {
      MoviesTask([wb_movie quickTimeMovie], 0);    // QTKit is not doing this automatically
    }
  }
}

#pragma mark -
- (id<WBMovieDrawer>)movieDrawer {
  return wb_drawer;
}
- (void)setMovieDrawer:(id<WBMovieDrawer>)aLayer {
  wb_drawer = aLayer;
}
- (BOOL)shouldNotifyDrawer {
  return wb_mtFlag.notify;
}
- (void)setShouldNotifyDrawer:(BOOL)shouldNotify {
  SPXFlagSet(wb_mtFlag.notify, shouldNotify);
  if (shouldNotify) {
    [[self visualContext] setDelegate:self];
  } else {
    [[self visualContext] setDelegate:nil];
  }
}

- (void)visualContext:(WBQTVisualContext *)ctxt imageIsAvailable:(CVImageBufferRef)anImage time:(const CVTimeStamp *)timeStamp {
  [self setCurrentFrame:anImage];
  [wb_drawer frameDidChange:self];
}

- (CGColorSpaceRef)outputColorSpace {
  return [wb_context outputColorSpace];
}
- (void)setOutputColorSpace:(CGColorSpaceRef)aColorSpace {
  [wb_context setOutputColorSpace:aColorSpace];
}

//- (void)wb_movieRateDidChange:(NSNotification *)aNotification {
//  CGFloat rate = [[aNotification object] rate];
//  if (!WBRealEquals(rate, 0)) {
//    [self setShouldNotifyDrawer:NO];
//  } else if (WBRealEquals(rate, 0)) {
//    [self setShouldNotifyDrawer:YES];
//  }
//}

@end

@implementation WBFileMovie

- (void)wb_setMovie:(QTMovie *)aMovie visualContext:(WBQTVisualContext *)ctxt {
  CGFloat rate = ctxt ? [aMovie rate] : 0;
  if (fnonzero(rate)) [aMovie stop];
  // WARNING: QTMovie uses its own qt context, and so, when calling
  // setVisualContext: it does not replace it, but just register it and transfert
  // message from its internal context to our own context (like image ready).
  // If formats are not compatible it may involved time consuming conversion.
  GetMovieVisualContext([aMovie quickTimeMovie], &wb_backup);
  SetMovieVisualContext([aMovie quickTimeMovie], [ctxt quickTimeContext]);
  if (wb_backup) QTVisualContextTask(wb_backup);
  //[aMovie setVisualContext:[ctxt quickTimeContext]];
  if (fnonzero(rate)) [aMovie setRate:rate];
}

- (id)initWithMovie:(QTMovie *)aMovie {
  NSParameterAssert([aMovie visualContext] == nil);
  return [super initWithMovie:aMovie];
}

- (void)configureMovie:(QTMovie *)aMovie {
  [super configureMovie:aMovie];
  if ([self visualContext])
    [self wb_setMovie:aMovie visualContext:[self visualContext]];
}

- (void)cleanupMovie:(QTMovie *)aMovie {
  [super cleanupMovie:aMovie];
  // restore original context
  SetMovieVisualContext([aMovie quickTimeMovie], wb_backup);
}

- (void)setVisualContext:(WBQTVisualContext *)ctxt {
  [super setVisualContext:ctxt];
  [self wb_setMovie:[self movie] visualContext:ctxt];
}

@end

#endif
