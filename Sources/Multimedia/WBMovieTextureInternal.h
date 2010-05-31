/*
 *  WBMovieTextureInternal.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBMovieTexture.h)

#import <QTKit/QTKit.h>

@class WBQTVisualContext;
@interface WBMovieTexture ()

- (void)setMovie:(QTMovie *)aMovie;

- (void)dispose;

- (void)configureMovie:(QTMovie *)aMovie;
- (void)cleanupMovie:(QTMovie *)aMovie; // remove all movie delegate, context, etc...

- (WBQTVisualContext *)visualContext;
- (void)setVisualContext:(WBQTVisualContext *)ctxt;

- (void)setCurrentFrame:(CVImageBufferRef)aFrame;

@end

@interface WBStreamingMovie : WBMovieTexture {
@private
  CVPixelBufferPoolRef wb_pool; // per movie (thread safety)
  ICMDecompressionSessionRef wb_icmSession; // per movie (thread safety)
}

@end
