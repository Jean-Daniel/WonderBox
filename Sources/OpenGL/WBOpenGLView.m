/*
 *  WBOpenGLView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBOpenGLView.h>
#import <WonderBox/WBGeometry.h>

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>

@implementation WBOpenGLView

#pragma mark -
- (BOOL)isOpaque {
  return !wb_glvFlags.transparent;
}
- (void)setOpaque:(BOOL)isOpaque {
  GLint opacity = isOpaque ? 1 : 0;
  SPXFlagSet(wb_glvFlags.transparent, !isOpaque);
  CGLContextObj glctxt = [[self openGLContext] CGLContextObj];
  CGLLockContext(glctxt);
  [[self openGLContext] setValues:&opacity forParameter:NSOpenGLCPSurfaceOpacity];
  CGLUnlockContext(glctxt);
}

- (BOOL)supportsSubview {
  return wb_glvFlags.subview;
}
- (void)setSupportsSubview:(BOOL)flag {
  GLint order = flag ? -1 : 1;
  SPXFlagSet(wb_glvFlags.subview, flag);
  CGLContextObj glctxt = [[self openGLContext] CGLContextObj];
  CGLLockContext(glctxt);
  [[self openGLContext] setValues:&order forParameter:NSOpenGLCPSurfaceOrder];
  CGLUnlockContext(glctxt);
}

- (BOOL)ignoresUserScaleFactor {
  return !wb_glvFlags.scales;
}
- (void)setIgnoresUserScaleFactor:(BOOL)flag {
  SPXFlagSet(wb_glvFlags.scales, !flag);
}

#pragma mark Live resizing
- (void)viewWillStartLiveResize {
  // during live resize, the frame rate should be greater than
  // the screen refresh rate to avoid glitch.
  if(wb_glvFlags.drawResize) {
    // save context settings
    GLint swap = 0;
    CGLContextObj glctxt = [[self openGLContext] CGLContextObj];
    CGLLockContext(glctxt);
    [[self openGLContext] getValues:&swap forParameter:NSOpenGLCPSwapInterval];
    SPXFlagSet(wb_glvFlags.syncSwap, swap);
    if (swap) {
      swap = 0;
      [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
    }
    CGLUnlockContext(glctxt);
  }
}

- (void)viewDidEndLiveResize {
  if(!wb_glvFlags.drawResize) {
    [self setNeedsDisplay:YES];
  } else {
    // restore context settings
    if (wb_glvFlags.syncSwap) {
      CGLContextObj glctxt = [[self openGLContext] CGLContextObj];
      GLint swap = wb_glvFlags.syncSwap;
      CGLLockContext(glctxt);
      [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];
      CGLUnlockContext(glctxt);
    }
  }
}

- (NSRect)convertRectToOpenGLSpace:(NSRect)aRect {
  if (![self ignoresUserScaleFactor]) {
    CGFloat factor = WBWindowUserSpaceScaleFactor([self window]);
    aRect.origin.x /= factor;
    aRect.origin.y /= factor;
    aRect.size.width /= factor;
    aRect.size.height /= factor;
  }
  return aRect;
}

- (NSRect)convertRectFromOpenGLSpace:(NSRect)aRect {
  if (![self ignoresUserScaleFactor]) {
    CGFloat factor = WBWindowUserSpaceScaleFactor([self window]);
    aRect.origin.x *= factor;
    aRect.origin.y *= factor;
    aRect.size.width *= factor;
    aRect.size.height *= factor;
  }
  return aRect;
}

// good practice to lock around update
- (void)update {
  CGLLockContext([[self openGLContext] CGLContextObj]);
  [super update];
  CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)reshape {
  CGLContextObj CGL_MACRO_CONTEXT = [[self openGLContext] CGLContextObj];
  CGLLockContext(CGL_MACRO_CONTEXT);
  [super reshape];
  wb_glvFlags.reshape = 1;
  CGLUnlockContext(CGL_MACRO_CONTEXT);

  if(wb_glvFlags.drawResize)
    [self drawRect:[self bounds]]; // reduce glitch
  else
    [self setNeedsDisplay:YES];
}

- (void)reshape:(NSRect)bounds {
  CGLContextObj CGL_MACRO_CONTEXT = [[self openGLContext] CGLContextObj];
  NSRect theBounds = [self bounds];
  // reset current viewport
  if(NSIsEmptyRect(theBounds)) {
    glViewport(0, 0, 1, 1);
  } else {
    glViewport(0, 0, (GLuint)NSWidth(theBounds), (GLuint)NSHeight(theBounds));  // set the viewport
  }

  glMatrixMode(GL_PROJECTION);   // select the projection matrix
  glLoadIdentity();              // reset it

  theBounds = [self convertRectToOpenGLSpace:theBounds];
  if(NSIsEmptyRect(theBounds)) {
    glOrtho(0, 1, 0, 1, -1, 1);
  } else {
    glOrtho(0, NSWidth(theBounds), 0, NSHeight(theBounds), -1, 1);
  }
}

- (void)prepareOpenGL {
  [super prepareOpenGL];
  CGLContextObj ctxt = [[self openGLContext] CGLContextObj];
  if (ctxt) {
    GLint value;
    CGLLockContext(ctxt);
    CGLPixelFormatObj format = CGLGetPixelFormat(ctxt);
    if (kCGLNoError == CGLDescribePixelFormat(format, 0, kCGLPFADoubleBuffer, &value))
      wb_glvFlags.doublebuf = value ? 1 : 0;

    CGLUnlockContext(ctxt);
  }
}

- (void)drawRect:(NSRect)aRect {
  if (wb_glvFlags.subview) // must be transparent, so clear the Quartz Context.
    CGContextClearRect([NSGraphicsContext currentGraphicsPort], NSRectToCGRect(aRect));

  [self refresh];
}

- (void)refresh {
  NSOpenGLContext *ctxt = [self openGLContext];
  if (ctxt) {
    [ctxt makeCurrentContext];
    CGLLockContext([ctxt CGLContextObj]);
    NSRect bounds = [self bounds];
    if (wb_glvFlags.reshape) {
      [self reshape:bounds];
      wb_glvFlags.reshape = 0;
    }

    [self glDraw:bounds];

    [self flushBuffer];
    CGLUnlockContext([ctxt CGLContextObj]);
  }
}

- (void)glDraw:(NSRect)dirtyRect {
  CGLContextObj CGL_MACRO_CONTEXT = [[self openGLContext] CGLContextObj];

  glClearColor(0, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
}

- (void)flushBuffer {
  if (wb_glvFlags.doublebuf)
    [[self openGLContext] flushBuffer];
  else {
    CGLContextObj CGL_MACRO_CONTEXT = [[self openGLContext] CGLContextObj];
    glFlush();
  }
}

@end
