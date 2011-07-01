/*
 *  WBGLString.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBGLStringBox.h)

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>

@interface WBGLStringLayer ()

- (BOOL)needsUpdateTexture;
- (void)setNeedsUpdateTexture:(BOOL)update;
- (void)wb_didProcessEditing:(NSNotification *)aNotification;

@end

@implementation WBGLStringLayer
#pragma mark Deallocs

- (void)deleteTexture {
  if (wb_texName && wb_glctxt) {
    CGLContextObj CGL_MACRO_CONTEXT = wb_glctxt;
    glDeleteTextures(1, &wb_texName);
    wb_texName = 0;

    if (wb_buffer) free(wb_buffer);
    wb_blength = 0;
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setOpenGLContext:nil];
  wb_dealloc();
}

#pragma mark -
#pragma mark Update tracking
- (BOOL)needsUpdateTexture {
  return wb_gslFlags.dirty;
}
- (void)setNeedsUpdateTexture:(BOOL)update {
  WBFlagSet(wb_gslFlags.dirty, update);
}

- (void)setTextStorage:(NSTextStorage *)aStorage {
  [super setTextStorage:aStorage];
  [self setNeedsUpdateTexture:YES];
  [self setMultipleThreadsEnabled:YES];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(wb_didProcessEditing:)
                                               name:NSTextStorageDidProcessEditingNotification
                                             object:aStorage];
}

- (void)didUpdate {
  [self setNeedsUpdateTexture:YES];
}

- (void)wb_didProcessEditing:(NSNotification *)aNotification {
  [self setNeedsUpdateTexture:YES];
}

- (void)setCornerRadius:(CGFloat)aRadius {
  if (fnotequal(aRadius, [self cornerRadius])) {
    [super setCornerRadius:aRadius];
    [self setNeedsUpdateTexture:YES];
  }
}
- (void)setBorderColor:(NSColor *)color {
  if (![color isEqual:[self borderColor]]) {
    [super setBorderColor:color];
    [self setNeedsUpdateTexture:YES];
  }
}
- (void)setBackgroundColor:(NSColor *)color {
  if (![color isEqual:[self backgroundColor]]) {
    [super setBackgroundColor:color];
    [self setNeedsUpdateTexture:YES];
  }
}

#pragma mark -
- (BOOL)shouldAntialias {
  return !wb_gslFlags.sharp;
}
- (void)setShouldAntialias:(BOOL)shouldAntialias {
  WBFlagSet(wb_gslFlags.sharp, !shouldAntialias);
  [self setNeedsUpdateTexture:YES];
}

- (CGFloat)userSpaceScaleFactor {
  if (wb_userScale <= 0) return 1;
  return wb_userScale;
}
- (void)setUserSpaceScaleFactor:(CGFloat)aFactor {
  if (fnotequal(wb_userScale, aFactor)) {
    wb_userScale = aFactor;
    [self setNeedsUpdateTexture:YES];
  }
}

- (CGLContextObj)openGLContext {
  return wb_glctxt;
}

- (void)setOpenGLContext:(CGLContextObj)aContext {
  if (wb_glctxt != aContext) {
    if (wb_glctxt) {
      [self deleteTexture];
      CGLReleaseContext(wb_glctxt);
    }
    wb_glctxt = aContext ? CGLRetainContext(aContext) : nil;
    [self setNeedsUpdateTexture:YES];
  }
}

#pragma mark -
- (void)updateTexture {
  if (!wb_glctxt) return;

  /* the OpenGL context is never flipped */
  CGSize previousSize = wb_texBounds.size;
  wb_texBounds = NSRectToCGRect([self bounds:NO]);
  if (CGRectIsEmpty(wb_texBounds)) {
    [self deleteTexture]; // cleanup cache
    return;
  }

  if (wb_userScale > 0) {
    wb_texBounds.size.width *= wb_userScale;
    wb_texBounds.size.height *= wb_userScale;
  }
  wb_texBounds = CGRectIntegral(wb_texBounds);

  if (wb_texBounds.size.width * 4 > NSUIntegerMax)
    return;

  /* 16 bytes boundary */
  NSUInteger bytePerRow = (NSUInteger)(wb_texBounds.size.width * 4);
  if (bytePerRow * wb_texBounds.size.height > NSUIntegerMax)
    return;

  NSUInteger datalen = (NSUInteger)(bytePerRow * wb_texBounds.size.height);

  CGLLockContext(wb_glctxt);
  /* reduce buffer size when needed */
  if (datalen > wb_blength || datalen < wb_blength / 2) {
    wb_blength = datalen;
    if (wb_buffer) wb_buffer = reallocf(wb_buffer, wb_blength);
    else wb_buffer = malloc(wb_blength);
    if (!wb_buffer) {
      WBCLogError("Invalid buffer size. cannot allocate memory: %s", strerror(errno));
      [self deleteTexture]; // cleanup cache
      return;
    }
  }

  CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef bmapContext = CGBitmapContextCreate(wb_buffer, (size_t)wb_texBounds.size.width, (size_t)wb_texBounds.size.height,
                                                   8, bytePerRow, cspace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
  CGColorSpaceRelease(cspace);
  WBAssert(bmapContext, @"invalid bitmap context");

  CGContextSetShouldAntialias(bmapContext, [self shouldAntialias]);
  CGContextSetShouldSmoothFonts(bmapContext, [self shouldAntialias]);
  CGContextSetInterpolationQuality(bmapContext, kCGInterpolationHigh);

  /* flip the context */
  CGContextClearRect(bmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bmapContext), CGBitmapContextGetHeight(bmapContext)));
  CGContextTranslateCTM(bmapContext, 0, CGBitmapContextGetHeight(bmapContext));
  CGContextScaleCTM(bmapContext, 1, -1);

  if (wb_userScale > 0)
    CGContextScaleCTM(bmapContext, wb_userScale, wb_userScale);

  // need flipped coord
  NSRect bounds = [self bounds:YES];
  CGContextTranslateCTM(bmapContext, -bounds.origin.x, -bounds.origin.y);

  [self drawAtPoint:NSZeroPoint context:bmapContext];

  CGContextRelease(bmapContext);

  CGLContextObj CGL_MACRO_CONTEXT = wb_glctxt;
  glPushAttrib(GL_TEXTURE_BIT);

  glColor3f(1, 1, 1);
  if (0 == wb_texName) glGenTextures (1, &wb_texName);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, wb_texName);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLuint)wb_texBounds.size.width);

  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE); // (fast) extension
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_SHARED_APPLE);

  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  if (CGSizeEqualToSize(previousSize, wb_texBounds.size)) {
    glTexSubImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, 0, 0, (GLsizei)wb_texBounds.size.width, (GLsizei)wb_texBounds.size.height,
                    GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, wb_buffer);
  } else {
    glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, (GLsizei)wb_texBounds.size.width, (GLsizei)wb_texBounds.size.height,
                 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, wb_buffer);
  }

  glPopAttrib();
  CGLUnlockContext(wb_glctxt);

  [self setNeedsUpdateTexture:NO];
}

- (void)updateTextureIfNeeded {
  if (![self needsUpdateTexture]) return;
  [self updateTexture];
}

#pragma mark -
#pragma mark Accessors

- (GLuint)textureName { return wb_texName; }
- (CGSize)textureSize { return wb_texBounds.size; }

#pragma mark -
#pragma mark Drawing
- (void)drawTextureAtPoint:(CGPoint)aPoint {
  [self drawTextureAtPoint:aPoint colors:NULL context:nil];
}
- (void)drawTextureAtPoint:(CGPoint)aPoint colors:(GLfloat[16])colors {
  [self drawTextureAtPoint:aPoint colors:colors context:nil];
}

- (void)drawTextureAtPoint:(CGPoint)aPoint colors:(GLfloat[16])colors context:(CGLContextObj)theContext {
  //WBAssert(wb_glctxt == CGLGetCurrentContext(), @"invalid GL context");
  if ([self needsUpdateTexture])
    [self updateTexture];

  if (wb_texName) {
    CGLContextObj CGL_MACRO_CONTEXT = theContext ? : wb_glctxt;
    glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT); // GL_COLOR_BUFFER_BIT for glBlendFunc, GL_ENABLE_BIT for glEnable / glDisable

    glEnable(GL_TEXTURE_RECTANGLE_ARB);

    /* adjust bounds */
    aPoint.x += wb_texBounds.origin.x;
    aPoint.y += wb_texBounds.origin.y;

    CGSize imgSize = wb_texBounds.size;
    if (wb_userScale > 0) {
      imgSize.width /= wb_userScale;
      imgSize.height /= wb_userScale;
    }

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, wb_texName);
    glBegin(GL_QUADS);
    if (colors) glColor4f(colors[0], colors[1], colors[2], colors[3]);
    glTexCoord2d(0, wb_texBounds.size.height); // draw upper left in world coordinates
    glVertex2d(aPoint.x, aPoint.y);

    if (colors) glColor4f(colors[4], colors[5], colors[6], colors[7]);
    glTexCoord2d(0, 0); // draw lower left in world coordinates
    glVertex2d(aPoint.x, aPoint.y + imgSize.height);

    if (colors) glColor4f(colors[8], colors[9], colors[10], colors[11]);
    glTexCoord2d(wb_texBounds.size.width, 0); // draw lower right in world coordinates
    glVertex2d(aPoint.x + imgSize.width, aPoint.y + imgSize.height);

    if (colors) glColor4f(colors[12], colors[13], colors[14], colors[15]);
    glTexCoord2d(wb_texBounds.size.width, wb_texBounds.size.height); // draw upper right in world coordinates
    glVertex2d(aPoint.x + imgSize.width, aPoint.y);
    glEnd();

    glPopAttrib();
  }
}

@end

