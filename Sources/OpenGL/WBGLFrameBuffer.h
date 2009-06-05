/*
 *  WBGLFrameBuffer.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <OpenGL/OpenGL.h>

enum {
  kWBGLAttachementTypeBuffer  = 1,
  kWBGLAttachementTypeTexture = 2,
};

@interface WBGLFrameBufferAttachement : NSObject {
@private  
  GLuint wb_name;
  GLenum wb_target;
  GLuint wb_width, wb_height;
  
  struct {
    unsigned int type:2;
    unsigned int zoff:7;
    unsigned int level:7;
  } wb_fbaFlags;
}

+ (id)depthBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)aContext;
+ (id)stencilBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)aContext;

- (id)initWithRendererBuffer:(GLint)aBuffer width:(GLuint)w height:(GLuint)h;

//- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget context:(CGLContextObj)theContext;

- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget width:(GLuint)w height:(GLuint)h;
- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget level:(GLint)aLevel width:(GLuint)w height:(GLuint)h;
- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget level:(GLint)aLevel zOffset:(GLint)offset width:(GLuint)w height:(GLuint)h;

/* helper */
- (id)initRendererBufferWithFormat:(GLenum)format width:(GLuint)w height:(GLuint)h context:(CGLContextObj)CGL_MACRO_CONTEXT;

// destroy underlying object
- (void)delete:(CGLContextObj)aContext;

- (NSUInteger)type;

- (CGSize)size;

- (GLuint)name;
- (GLenum)target;

- (GLint)level; // texture only
- (GLint)zOffset; // 3D texture

@end

enum {
  kWBGLFrameBufferNoBuffer = -1,
};

@interface WBGLFrameBuffer : NSObject {
@private
  CGLContextObj wb_glctxt;
  
  GLuint wb_fbo;
  
  GLint wb_viewport[4];
  NSMapTable *wb_attachements;
  WBGLFrameBufferAttachement *wb_depth, *wb_stencil;
}

- (id)initWithContext:(CGLContextObj)aContext;

// cleanup underlying gl objects
// use to release resources in a deterministic way.
- (void)delete;

- (GLenum)status;
- (GLenum)status:(CGLContextObj)aContext;
- (GLint)frameBufferObject;
- (CGLContextObj)CGLContextObj;

- (BOOL)bind;
- (void)unbind;

- (BOOL)bind:(CGLContextObj)aContext;
- (void)unbind:(CGLContextObj)aContext;

// mode can be GL_READ_FRAMEBUFFER_EXT or GL_DRAW_FRAMEBUFFER_EXT
- (BOOL)bindMode:(GLenum)mode context:(CGLContextObj)aContext;
- (void)unbindMode:(GLenum)mode context:(CGLContextObj)aContext;

- (NSUInteger)maxBufferCount;

// -1 mean GL_NONE
- (void)setReadBuffer:(NSInteger)anIdx;
- (void)setWriteBuffer:(NSInteger)anIdx;

- (void)setReadBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext;
- (void)setWriteBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext;

- (WBGLFrameBufferAttachement *)depthBuffer;
- (void)setDepthBuffer:(WBGLFrameBufferAttachement *)aBuffer;

- (WBGLFrameBufferAttachement *)stencilBuffer;
- (void)setStencilBuffer:(WBGLFrameBufferAttachement *)aBuffer;

- (NSArray *)colorBuffers;
- (WBGLFrameBufferAttachement *)colorBufferAtIndex:(NSUInteger)anIndex;
- (void)setColorBuffer:(WBGLFrameBufferAttachement *)aBuffer atIndex:(NSUInteger)anIndex;

@end

WB_EXPORT
NSString *WBGLFrameBufferGetErrorString(GLenum error);
