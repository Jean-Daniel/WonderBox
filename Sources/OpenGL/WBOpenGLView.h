/*
 *  WBOpenGLView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBGLFrameBuffer.h)

@interface WBOpenGLView : NSOpenGLView {
@private
  struct _wb_glvFlags {
    unsigned int scales:1;
    unsigned int reshape:1;
    unsigned int subview:1;
    unsigned int doublebuf:1;
    unsigned int drawResize:1;
    unsigned int transparent:1;
    unsigned int syncSwap:8;
    unsigned int reserved:2;
  } wb_glvFlags;
}

// set to false to draw transparent context
- (BOOL)isOpaque;
- (void)setOpaque:(BOOL)isOpaque;

// required to be able to draw subview
- (BOOL)supportsSubview;
- (void)setSupportsSubview:(BOOL)flag;

/* by default, opengl is not scaled */
- (BOOL)ignoresUserScaleFactor;
- (void)setIgnoresUserScaleFactor:(BOOL)flag;

- (NSRect)convertRectToOpenGLSpace:(NSRect)aRect;
- (NSRect)convertRectFromOpenGLSpace:(NSRect)aRect;

- (void)flushBuffer;

// safe to call it outside of the drawing loop
- (void)drawRect:(NSRect)aRect;

/* protected */
// context locked
- (void)reshape:(NSRect)bounds;
// - Context locked.
// - Do not flush in this method.
- (void)glDraw:(NSRect)dirtyRect;

@end
