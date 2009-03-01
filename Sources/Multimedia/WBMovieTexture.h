/*
 *  WBMovieTexture.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import <QTKit/QTKit.h>
#import <CoreVideo/CoreVideo.h>

@class QTMovie;
@protocol WBMovieDrawer;
@class WBQTVisualContext;
@interface WBMovieTexture : NSObject {
@private
  QTTime wb_time;
  QTMovie *wb_movie;
  __weak id<WBMovieDrawer> wb_drawer;
  
  CVImageBufferRef wb_frame;
  CVImageBufferRef wb_locked;
  WBQTVisualContext *wb_context;

  struct _wb_mtFlag {
    unsigned int time:1;
    unsigned int ltime:1;
    unsigned int notify:1;
    unsigned int reserved:5;
  } wb_mtFlag;
}

- (id)initWithMovie:(QTMovie *)aMovie;

- (QTMovie *)movie;

- (void)lock;
- (void)unlock;
- (QTTime)currentTime;
- (CVOpenGLTextureRef)currentFrame;

- (void)reclaimResources;
- (BOOL)update:(const CVTimeStamp *)aTimestamp;
- (void)setOpenGLContext:(CGLContextObj)aContext format:(CGLPixelFormatObj)aFormat;

- (id<WBMovieDrawer>)movieDrawer;
- (void)setMovieDrawer:(id<WBMovieDrawer>)aLayer;

- (BOOL)shouldNotifyDrawer;
- (void)setShouldNotifyDrawer:(BOOL)shouldNotify;

/* does not require lock */
- (CVOpenGLTextureRef)copyCurrentFrame;

- (CGColorSpaceRef)outputColorSpace;
- (void)setOutputColorSpace:(CGColorSpaceRef)aColorSpace;

@end

@protocol WBMovieDrawer 
- (void)frameDidChange:(WBMovieTexture *)aTexture;
@end

