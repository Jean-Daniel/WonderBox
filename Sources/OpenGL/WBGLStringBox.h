/*
 *  WBGLString.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBStringLayer.h>

#include <OpenGL/CGLTypes.h>

WB_OBJC_EXPORT
@interface WBGLStringLayer : WBStringLayer {
@private
  GLuint wb_texName;
  CGRect wb_texBounds;
  CGFloat wb_userScale;

  CGLContextObj wb_glctxt; // current context at time of texture creation

  /* cache */
  void *wb_buffer;
  NSUInteger wb_blength;
  struct {
    unsigned int sharp:1;
    unsigned int dirty:1;
    unsigned int reserved:7;
  } wb_gslFlags;
}

- (GLuint)textureName; // 0 if no texture allocated
- (CGSize)textureSize; // actually size of texture generated in texels, (0, 0) if no texture allocated

- (void)updateTextureIfNeeded; // generates the texture without drawing texture to current context

- (CGLContextObj)openGLContext;
- (void)setOpenGLContext:(CGLContextObj)aContext;

- (BOOL)shouldAntialias;
- (void)setShouldAntialias:(BOOL)shouldAntialias;

- (CGFloat)userSpaceScaleFactor;
- (void)setUserSpaceScaleFactor:(CGFloat)aFactor;

/* draw using opengl */
- (void)drawTextureAtPoint:(CGPoint)aPoint;

/* colors: upper left / lower left / lower right / upper right */
- (void)drawTextureAtPoint:(CGPoint)aPoint colors:(GLfloat[16])colors;
- (void)drawTextureAtPoint:(CGPoint)aPoint colors:(GLfloat[16])colors context:(CGLContextObj)theContext;

@end
