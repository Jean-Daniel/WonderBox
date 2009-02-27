//
//  WBOpenGLView.m
//  QuickShow
//
//  Created by Jean-Daniel Dupas on 20/02/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import WBHEADER(WBOpenGLView.h)
#import WBHEADER(WBGeometry.h)

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>

@implementation WBOpenGLView

#pragma mark -
- (BOOL)isOpaque {
  return !wb_glvFlags.transparent;
}
- (void)setOpaque:(BOOL)isOpaque {
  GLint opacity = isOpaque ? 1 : 0;
  WBFlagSet(wb_glvFlags.transparent, !isOpaque);
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
  WBFlagSet(wb_glvFlags.subview, flag);
  CGLContextObj glctxt = [[self openGLContext] CGLContextObj];
  CGLLockContext(glctxt);
  [[self openGLContext] setValues:&order forParameter:NSOpenGLCPSurfaceOrder];
  CGLUnlockContext(glctxt);
}

- (BOOL)ignoresUserScaleFactor {
  return !wb_glvFlags.scales;
}
- (void)setIgnoresUserScaleFactor:(BOOL)flag {
  WBFlagSet(wb_glvFlags.scales, !flag);
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
    WBAssert(swap < (1 << 8), @"sync swap overflow");
    wb_glvFlags.syncSwap = swap;
    if (swap > 0) {
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
    if (wb_glvFlags.syncSwap > 0) {
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
    glViewport(0, 0, NSWidth(theBounds), NSHeight(theBounds));  // set the viewport
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

- (void)drawRect:(NSRect)aRect {
  if (wb_glvFlags.subview) // must be transparent, so clear the Quartz Context.
    CGContextClearRect([[NSGraphicsContext currentContext] graphicsPort], NSRectToCGRect(aRect));
  
  [[self openGLContext] makeCurrentContext];
  CGLLockContext([[self openGLContext] CGLContextObj]);
  if (wb_glvFlags.reshape) {
    [self reshape:[self bounds]];
    wb_glvFlags.reshape = 0;
  }
  
  [self glDraw:aRect];
  
  [[self openGLContext] flushBuffer];
  CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)glDraw:(NSRect)dirtyRect {
  CGLContextObj CGL_MACRO_CONTEXT = [[self openGLContext] CGLContextObj];
  
  glClearColor(0, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  
}

@end
