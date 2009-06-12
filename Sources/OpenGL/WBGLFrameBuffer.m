/*
 *  WBGLFrameBuffer.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBGLFrameBuffer.h)

#import <OpenGL/CGLMacro.h>

@implementation WBGLFrameBuffer

- (id)initWithContext:(CGLContextObj)CGL_MACRO_CONTEXT {
  if (self = [super init]) {
    glGenFramebuffersEXT(1, &wb_fbo);
    wb_glctxt = CGLRetainContext(CGL_MACRO_CONTEXT);
    wb_attachements = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    
    // Sanity check against maximum OpenGL texture size
    // If bigger adjust to maximum possible size while maintain the aspect ratio
//    GLint maxTexSize;
//    CGLContextObj CGL_MACRO_CONTEXT = wb_glctxt;
//    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTexSize);
//    if (wb_width > (GLuint)maxTexSize || wb_height > (GLuint)maxTexSize) {
//      CGFloat imageAspectRatio = wb_width / wb_height;
//      if (imageAspectRatio > 1) {
//        wb_width = maxTexSize; 
//        wb_height = maxTexSize / imageAspectRatio;
//      } else {
//        wb_width = maxTexSize * imageAspectRatio ;
//        wb_height = maxTexSize; 
//      }
//    }
    
  }
  return self;
}

- (void)delete {
  if (wb_glctxt) {
    CGLLockContext(wb_glctxt);
    [wb_depth release];
    wb_depth = nil;
    [wb_stencil release];
    wb_stencil = nil;
    if (wb_attachements) {
      NSFreeMapTable(wb_attachements);
      wb_attachements = nil;
    }
    if (wb_fbo) {
      CGLContextObj CGL_MACRO_CONTEXT = wb_glctxt;
      glDeleteFramebuffersEXT(1, &wb_fbo);
      wb_fbo = 0;
    }
    CGLUnlockContext(wb_glctxt);
    CGLReleaseContext(wb_glctxt);
    wb_glctxt = nil;
  }
}

- (void)dealloc {
  [self delete]; 
  [super dealloc];
}

- (GLenum)status {
  return [self status:nil];
}
- (GLenum)status:(CGLContextObj)aContext {
  CGLContextObj CGL_MACRO_CONTEXT = aContext ? : wb_glctxt;
  
  GLint save;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_EXT, &save);
  if ((GLuint)save != wb_fbo)
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, wb_fbo);
  GLenum status = glCheckFramebufferStatusEXT(GL_DRAW_FRAMEBUFFER_EXT);
  
  if ((GLuint)save != wb_fbo)
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, save);
  
  return GL_FRAMEBUFFER_COMPLETE_EXT == status ? 0 : status;
}

- (GLint)frameBufferObject {
  return wb_fbo;
}

- (CGLContextObj)CGLContextObj { return wb_glctxt; }

WB_INLINE 
void __WBGLFrameBufferAttach(CGLContextObj CGL_MACRO_CONTEXT, GLuint fbo, 
                             GLenum slot, WBGLFrameBufferAttachement *buffer) {
  GLint save;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING_EXT, &save);
  if ((GLuint)save != fbo)
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, fbo);
  switch ([buffer type]) {
    case 0:
      glFramebufferRenderbufferEXT(GL_DRAW_FRAMEBUFFER_EXT, slot, 0, 0);
      break;
    case kWBGLAttachementTypeBuffer:
      glFramebufferRenderbufferEXT(GL_DRAW_FRAMEBUFFER_EXT, slot, 
                                   [buffer target], [buffer name]);
      break;
    case kWBGLAttachementTypeTexture:
      switch ([buffer target]) {
        case GL_TEXTURE_1D:
          glFramebufferTexture1DEXT(GL_DRAW_FRAMEBUFFER_EXT, slot, 
                                    [buffer target], [buffer name], [buffer level]);
          break;
        case GL_TEXTURE_3D:
          glFramebufferTexture3DEXT(GL_DRAW_FRAMEBUFFER_EXT, slot, 
                                    [buffer target], [buffer name], 
                                    [buffer level], [buffer zOffset]);
          break;
        default:
          glFramebufferTexture2DEXT(GL_DRAW_FRAMEBUFFER_EXT, slot, 
                                    [buffer target], [buffer name], [buffer level]);          
          break;
      }
      break;
  }
  if ((GLuint)save != fbo)
    glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, save);
}

- (WBGLFrameBufferAttachement *)depthBuffer {
  return wb_depth;
}
- (void)setDepthBuffer:(WBGLFrameBufferAttachement *)aBuffer {
  if (WBSetterRetain(&wb_depth, aBuffer)) {
    __WBGLFrameBufferAttach(wb_glctxt, wb_fbo, 
                            GL_DEPTH_ATTACHMENT_EXT, aBuffer);
  }
}

- (WBGLFrameBufferAttachement *)stencilBuffer {
  return wb_stencil;
}
- (void)setStencilBuffer:(WBGLFrameBufferAttachement *)aBuffer {
  if (WBSetterRetain(&wb_stencil, aBuffer)) {
    __WBGLFrameBufferAttach(wb_glctxt, wb_fbo, 
                            GL_STENCIL_ATTACHMENT_EXT, aBuffer);
  }  
}

- (NSArray *)colorBuffers {
  return NSAllMapTableValues(wb_attachements);
}
- (WBGLFrameBufferAttachement *)colorBufferAtIndex:(NSUInteger)anIndex {
  return NSMapGet(wb_attachements, (const void *)anIndex);
}
- (void)setColorBuffer:(WBGLFrameBufferAttachement *)aBuffer atIndex:(NSUInteger)anIndex {
  NSMapInsert(wb_attachements, (const void *)anIndex, aBuffer);
  __WBGLFrameBufferAttach(wb_glctxt, wb_fbo, 
                          GL_COLOR_ATTACHMENT0_EXT + anIndex, aBuffer);
}

- (BOOL)bind {
  return [self bindMode:GL_FRAMEBUFFER_EXT context:nil];
}
- (void)unbind {
  return [self unbindMode:GL_FRAMEBUFFER_EXT context:nil];
}

- (BOOL)bind:(CGLContextObj)aContext {
  return [self bindMode:GL_FRAMEBUFFER_EXT context:aContext];
}

- (void)unbind:(CGLContextObj)aContext {
  return [self unbindMode:GL_FRAMEBUFFER_EXT context:aContext];
}

WB_INLINE
GLenum __WBGLFBOBindingForMode(GLenum mode) {
  switch (mode) {
    case GL_FRAMEBUFFER_EXT:
      return GL_FRAMEBUFFER_BINDING_EXT;
    case GL_DRAW_FRAMEBUFFER_EXT:
      return GL_DRAW_FRAMEBUFFER_BINDING_EXT;
    case GL_READ_FRAMEBUFFER_EXT:
      return GL_READ_FRAMEBUFFER_BINDING_EXT;
  }
  WBThrowException(NSInvalidArgumentException, @"Invalid FBO mode");
}

// mode can be READ_FRAMEBUFFER_EXT or DRAW_FRAMEBUFFER_EXT
- (BOOL)bindMode:(GLenum)mode context:(CGLContextObj)aContext {
  CGLContextObj CGL_MACRO_CONTEXT = aContext ? : wb_glctxt;
  
  GLint save;
  glGetIntegerv(__WBGLFBOBindingForMode(mode), &save);
  WBAssert(GL_ZERO == glGetError(), @"error while getting actual FBO");
  
  if ((GLuint)save == wb_fbo) return YES;

  glBindFramebufferEXT(mode, wb_fbo);
  
  if (GL_ZERO == glGetError()) {
#if defined(DEBUG)
    GLenum status = glCheckFramebufferStatusEXT(mode);
    if (status != GL_FRAMEBUFFER_COMPLETE_EXT) {
      DLog(@"Warning trying to bind FBO but status: %@", WBGLFrameBufferGetErrorString(status));
      glBindFramebufferEXT(mode, save);
      return NO;
    }
#endif
    if (mode == GL_FRAMEBUFFER_EXT || mode == GL_DRAW_FRAMEBUFFER_EXT) {
      CGSize size = CGSizeMake(0, 0);
      if (wb_depth) 
        size = [wb_depth size];
      else if (wb_stencil) 
        size = [wb_stencil size];
      else {
        // infer size from the first attached color
        WBGLFrameBufferAttachement *buffer = nil;
        NSMapEnumerator iter = NSEnumerateMapTable(wb_attachements);
        if (NSNextMapEnumeratorPair(&iter, NULL, (void **)&buffer))
          size = [buffer size];
        NSEndMapTableEnumeration(&iter);
      }
      
      glGetIntegerv(GL_VIEWPORT, wb_viewport);			// Retrieves The Viewport Values (X, Y, Width, Height)
      // Set the viewport to the dimensions of our texture	
      glViewport(0, 0, size.width, size.height);
    }
  }
  return glGetError() == 0;
}

- (void)unbindMode:(GLenum)mode context:(CGLContextObj)aContext {
  CGLContextObj CGL_MACRO_CONTEXT = aContext ? : wb_glctxt;
  
  GLint actual = 0;
  glGetIntegerv(__WBGLFBOBindingForMode(mode), &actual);
  if ((GLuint)actual != wb_fbo) return;
  
  // restore view port
  if (mode == GL_FRAMEBUFFER_EXT || mode == GL_DRAW_FRAMEBUFFER_EXT)
    glViewport(wb_viewport[0], wb_viewport[1], wb_viewport[2], wb_viewport[3]);

  glBindFramebufferEXT(mode, 0);
}

- (void)setReadBuffer:(NSInteger)anIdx {
  [self setReadBuffer:anIdx context:nil];  
}
- (void)setWriteBuffer:(NSInteger)anIdx {
  [self setWriteBuffer:anIdx context:nil];  
}

- (void)setReadBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext {
  GLenum buffer;
  CGLContextObj CGL_MACRO_CONTEXT = aContext ? : wb_glctxt;
  if (anIdx < 0) buffer = GL_NONE;
  else buffer = GL_COLOR_ATTACHMENT0_EXT + anIdx;
  glReadBuffer(buffer);  
}

- (void)setWriteBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext {
  GLenum buffer;
  CGLContextObj CGL_MACRO_CONTEXT = aContext ? : wb_glctxt;
  if (anIdx < 0) buffer = GL_NONE;
  else buffer = GL_COLOR_ATTACHMENT0_EXT + anIdx;
  glDrawBuffer(buffer);    
}

- (NSUInteger)maxBufferCount {
  GLint value = 0;
  CGLContextObj CGL_MACRO_CONTEXT = wb_glctxt;
  glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS_EXT, &value);
  return value;
}

@end

@implementation WBGLFrameBufferAttachement

+ (id)depthBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)CGL_MACRO_CONTEXT {
  WBGLFrameBufferAttachement *buffer = nil;
  GLenum format;
  switch (bits) {
    default: format = 0; break;
    case 16: format = GL_DEPTH_COMPONENT16; break;
    case 24: format = GL_DEPTH_COMPONENT24; break;
    case 32: format = GL_DEPTH_COMPONENT32; break;
  }
  GLuint name = 0;
  if (format) {
    GLint save = 0;
    glGenRenderbuffersEXT(1, &name);
    glGetIntegerv(GL_RENDERBUFFER_BINDING_EXT, &save);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, name);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, format, w, h);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, save);
  }
  if (name) {
    buffer = [[[WBGLFrameBufferAttachement alloc] initWithRendererBuffer:name width:w height:h] autorelease];
    if (!buffer)
      glDeleteRenderbuffersEXT(1, &name);
  }
  return buffer;
}

+ (id)stencilBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)CGL_MACRO_CONTEXT {
  WBGLFrameBufferAttachement *buffer = nil;
  GLenum format;
  switch (bits) {
    default: format = 0; break;
    case 1: format = GL_STENCIL_INDEX1_EXT; break;
    case 4: format = GL_STENCIL_INDEX4_EXT; break;
    case 8: format = GL_STENCIL_INDEX8_EXT; break;
    case 16: format = GL_STENCIL_INDEX16_EXT; break;
  }
  GLuint name = 0;
  if (format) {
    GLint save = 0;
    glGenRenderbuffersEXT(1, &name);
    glGetIntegerv(GL_RENDERBUFFER_BINDING_EXT, &save);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, name);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, format, w, h);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, save);
  }
  if (name) {
    buffer = [[[WBGLFrameBufferAttachement alloc] initWithRendererBuffer:name width:w height:h] autorelease];
    if (!buffer)
      glDeleteRenderbuffersEXT(1, &name);
  }
  return buffer;
}

- (id)initWithName:(GLint)aName target:(GLenum)aTarget width:(GLuint)w height:(GLuint)h {
  if (self = [super init]) {
    wb_width = w;
    wb_height = h;
    wb_name = aName;
    wb_target = aTarget;
  }
  return self;
}

- (id)initWithRendererBuffer:(GLint)aBuffer width:(GLuint)w height:(GLuint)h {
  if (self = [self initWithName:aBuffer target:GL_RENDERBUFFER_EXT width:w height:h]) {
    wb_fbaFlags.type = kWBGLAttachementTypeBuffer;
  }
  return self;
}
//- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget context:(CGLContextObj)CGL_MACRO_CONTEXT {
//  GLint w, h;
//  glBindTexture(aTarget, aTexture);
//  glGetTexLevelParameteriv(aTarget, 0, GL_TEXTURE_WIDTH, &w);
//  glGetTexLevelParameteriv(aTarget, 0, GL_TEXTURE_HEIGHT, &h);
//  return [self initWithTexture:aTexture target:aTarget width:w height:h];
//}

- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget width:(GLuint)w height:(GLuint)h {
  return [self initWithTexture:aTexture target:aTarget level:0 zOffset:0 width:w height:h];
}
- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget level:(GLint)aLevel width:(GLuint)w height:(GLuint)h {
  return [self initWithTexture:aTexture target:aTarget level:aLevel zOffset:0 width:w height:h];  
}
- (id)initWithTexture:(GLint)aTexture target:(GLenum)aTarget level:(GLint)aLevel zOffset:(GLint)offset width:(GLuint)w height:(GLuint)h {
  if (self = [self initWithName:aTexture target:aTarget width:w height:h]) {
    wb_fbaFlags.type = kWBGLAttachementTypeTexture;
    wb_fbaFlags.zoff = offset;
    wb_fbaFlags.level = aLevel;
  }
  return self;  
}

- (id)initRendererBufferWithFormat:(GLenum)format width:(GLuint)w height:(GLuint)h context:(CGLContextObj)CGL_MACRO_CONTEXT {
  GLint save = 0; GLuint name = 0;
  glGenRenderbuffersEXT(1, &name);
  glGetIntegerv(GL_RENDERBUFFER_BINDING_EXT, &save);
  glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, name);
  glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, format, w, h);
  glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, save);
  
  return [self initWithRendererBuffer:name width:w height:h];
}

- (void)delete:(CGLContextObj)CGL_MACRO_CONTEXT {
  switch ([self type]) {
    case kWBGLAttachementTypeBuffer:
      glDeleteRenderbuffersEXT(1, &wb_name);
      break;
    case kWBGLAttachementTypeTexture:
      glDeleteTextures(1, &wb_name);
      break;
  }
}

- (NSUInteger)type {
  return wb_fbaFlags.type;
}

- (CGSize)size {
  return CGSizeMake(wb_width, wb_height);
}

- (GLuint)name {
  return wb_name;
}
- (GLenum)target {
  return wb_target;
}

- (GLint)level {
  return wb_fbaFlags.level;
}
- (GLint)zOffset {
  return wb_fbaFlags.zoff;
}

@end


#pragma mark ===== Validation =====
#define kOpenGLFramebufferUnsupported                   @"OpenGL framebuffer unsupported! Choose different format."
#define kOpenGLFramebufferIncompleteAttachement         @"OpenGL framebuffer incomplete attachment!"
#define kOpenGLFramebufferIncompleteMissingAttachement  @"OpenGL framebuffer incomplete missing attachment!"
#define KOpenGLFramebufferIncompleteDimensions          @"OpenGL framebuffer incomplete dimensions!"
#define kOpenGLFramebufferIncompleteFormats             @"OpenGL framebuffer incomplete formats!"
#define kOpenGLFramebufferIncompleteDrawBuffer          @"OpenGL framebuffer incomplete draw buffer!"
#define kOpenGLFramebufferIncompleteReadBuffer          @"OpenGL framebuffer incomplete read buffer!"
#define kOpenGLFramebufferDefaultMessage      					@"Undefined error !"

NSString *WBGLFrameBufferGetErrorString(GLenum error) {
  switch (error) {
    default: return kOpenGLFramebufferDefaultMessage;
    case GL_FRAMEBUFFER_COMPLETE_EXT: return nil;
    case GL_FRAMEBUFFER_UNSUPPORTED_EXT: return kOpenGLFramebufferUnsupported;
		case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT: return kOpenGLFramebufferIncompleteAttachement;
		case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT: return kOpenGLFramebufferIncompleteMissingAttachement;
		case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT: return KOpenGLFramebufferIncompleteDimensions;
		case GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT: return kOpenGLFramebufferIncompleteFormats;
		case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT: return kOpenGLFramebufferIncompleteDrawBuffer;
		case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT: return kOpenGLFramebufferIncompleteReadBuffer;
  }
}



