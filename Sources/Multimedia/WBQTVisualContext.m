/*
 *  WBQTVisualContext.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBQTVisualContext.h)

#include <pthread.h>

static
void _WBImageAvailableCallBack(QTVisualContextRef visualContext, const CVTimeStamp *timeStamp, void *refCon);

@implementation WBQTVisualContext

// use pthread as it is faster than synchronized
//#define WBQTVisualContextLock() pthread_mutex_lock(&wb_lock)
//#define WBQTVisualContextUnlock() pthread_mutex_unlock(&wb_lock)
#define WBQTVisualContextLock()
#define WBQTVisualContextUnlock()

- (id)initWithPixelBufferAttributes:(CFDictionaryRef)attributes {
  QTVisualContextRef ctxt = NULL;
  OSStatus err = QTPixelBufferContextCreate(kCFAllocatorDefault, attributes, &ctxt);
  if (noErr == err) {
    self = [self initWithQuickTimeContext:ctxt];
    QTVisualContextRelease(ctxt);
  } else {
    [self release];
    self = nil;
  }
  return self;  
}

- (id)initWithOpenGLContext:(CGLContextObj)aContext {
  return [self initWithOpenGLContext:aContext pixelFormat:NULL attributes:NULL];
}
- (id)initWithOpenGLContext:(CGLContextObj)aContext pixelFormat:(CGLPixelFormatObj)aFormat attributes:(CFDictionaryRef)attrs {
  NSParameterAssert(aContext);
  QTVisualContextRef ctxt = NULL;
  OSStatus err = QTOpenGLTextureContextCreate(kCFAllocatorDefault, aContext, aFormat ? : CGLGetPixelFormat(aContext), attrs, &ctxt);
  if (noErr == err) {
    self = [self initWithQuickTimeContext:ctxt];
    QTVisualContextRelease(ctxt);
  } else {
    [self release];
    self = nil;
  }
  return self;
}

- (id)initWithQuickTimeContext:(QTVisualContextRef)aContext {
  if (!aContext) {
    [self release];
    return nil;
  }
  if (self = [super init]) {
    wb_ctxt = QTVisualContextRetain(aContext);
    //pthread_mutex_init(&wb_lock, NULL);
  }
  return self;
}

- (void)dealloc {
  [self setDelegate:nil];
  //pthread_mutex_destroy(&wb_lock);
  if (wb_ctxt) QTVisualContextRelease(wb_ctxt);
  [super dealloc];
}

#pragma mark -
- (WBQTVisualContextType)type {
  CFStringRef type = [self attributeForKey:kQTVisualContextTypeKey];
  if (!type) return 0;
  if (CFEqual(type, kQTVisualContextType_PixelBuffer)) return kWBQTPixelBufferContext;
  if (CFEqual(type, kQTVisualContextType_OpenGLTexture)) return kWBQTOpenGLTextureContext;
  return 0;
}

- (QTVisualContextRef)quickTimeContext {
  return wb_ctxt;
}

- (CFTypeRef)attributeForKey:(CFStringRef)aKey {
  return [self attributeForKey:aKey error:NULL];
}
- (CFTypeRef)attributeForKey:(CFStringRef)aKey error:(OSStatus *)error {
  CFTypeRef attr = NULL;
  WBQTVisualContextLock();
  OSStatus err = QTVisualContextGetAttribute(wb_ctxt, aKey, &attr);
  WBQTVisualContextUnlock();
  if (error) *error = err;
  return attr;
}
- (OSStatus)setAttribute:(CFTypeRef)anAttribute forKey:(CFStringRef)aKey {
  WBQTVisualContextLock();
  OSStatus err = QTVisualContextSetAttribute(wb_ctxt, aKey, anAttribute);
  WBQTVisualContextUnlock();
  return err;
}

- (CGColorSpaceRef)workingColorSpace {
  return (CGColorSpaceRef)[self attributeForKey:kQTVisualContextWorkingColorSpaceKey error:nil];
}
- (void)setWorkingColorSpace:(CGColorSpaceRef)aColorspace {
  [self setAttribute:aColorspace forKey:kQTVisualContextWorkingColorSpaceKey];
}
- (void)setWorkingColorSpaceName:(CFStringRef)cgColorSpaceName {
  CGColorSpaceRef cs = CGColorSpaceCreateWithName(cgColorSpaceName);
  [self setWorkingColorSpace:cs];
  CGColorSpaceRelease(cs);
}

- (CGColorSpaceRef)outputColorSpace {
  return (CGColorSpaceRef)[self attributeForKey:kQTVisualContextOutputColorSpaceKey error:nil];
}
- (void)setOutputColorSpace:(CGColorSpaceRef)aColorspace {
  [self setAttribute:aColorspace forKey:kQTVisualContextOutputColorSpaceKey];
}
- (void)setOutputColorSpaceName:(CFStringRef)cgColorSpaceName {
  CGColorSpaceRef cs = CGColorSpaceCreateWithName(cgColorSpaceName);
  [self setOutputColorSpace:cs];
  CGColorSpaceRelease(cs);
}

- (BOOL)isNewImageAvailableForTime:(const CVTimeStamp *)timeStamp {
  WBQTVisualContextLock();
  BOOL result = QTVisualContextIsNewImageAvailable(wb_ctxt, timeStamp);
  WBQTVisualContextUnlock();
  return result;
}

- (CVImageBufferRef)copyImageForTime:(const CVTimeStamp *)timeStamp {
  return [self copyImageForTime:timeStamp allocator:kCFAllocatorDefault error:NULL];
}
- (CVImageBufferRef)copyImageForTime:(const CVTimeStamp *)timeStamp allocator:(CFAllocatorRef)allocator error:(OSStatus *)error {
  CVImageBufferRef frame = NULL;
  WBQTVisualContextLock();
  OSStatus err = QTVisualContextCopyImageForTime(wb_ctxt, allocator, timeStamp, &frame);
  WBQTVisualContextUnlock();
  if (error) *error = err;
  return frame;
}

- (void)task {
  WBQTVisualContextLock();
  QTVisualContextTask(wb_ctxt);
  WBQTVisualContextUnlock();
}
- (void)reclaimResources {
  WBQTVisualContextLock();
  QTVisualContextTask(wb_ctxt);
  WBQTVisualContextUnlock();
}

- (id)delegate {
  return wb_delegate;
}
- (void)setDelegate:(id)aDelegate {
  WBQTVisualContextLock();
  if (!wb_delegate && aDelegate) { verify_noerr(QTVisualContextSetImageAvailableCallback(wb_ctxt, _WBImageAvailableCallBack, self)); }
  else if (wb_delegate && !aDelegate) { verify_noerr(QTVisualContextSetImageAvailableCallback(wb_ctxt, NULL, nil)); }
  wb_delegate = aDelegate;
  WBQTVisualContextUnlock();
}

void _WBImageAvailableCallBack(QTVisualContextRef visualContext, const CVTimeStamp *timeStamp, void *refCon) {
  WBQTVisualContext *self = (WBQTVisualContext *)refCon;
  CVImageBufferRef frame;
  if (noErr == QTVisualContextCopyImageForTime(visualContext, kCFAllocatorDefault, timeStamp, &frame)) {
    [self->wb_delegate visualContext:self imageIsAvailable:frame time:timeStamp];
    CVBufferRelease(frame);
  }
}

@end

