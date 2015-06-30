/*
 *  WBBezelItemContent.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBezelItemContent.h>
#import <WonderBox/WBClassCluster.h>

#import <Cocoa/Cocoa.h>

WBClassCluster(WBBezelItemContent)

@interface WBBezelItemCustomView : WBBezelItemContent {
  @private
  NSView *wb_view;
}

- (id)initWithContent:(NSView *)content;

@end

@interface WBBezelItemImage : WBBezelItemCustomView {
  @private
  //NSImage *wb_image;
}

- (id)initWithContent:(NSImage *)content;

@end

@interface WBBezelItemText : WBBezelItemCustomView {
  @private
  //NSAttributedString *wb_text;
}

- (NSView *)textView;

@end

@interface WBClusterPlaceholder(WBBezelItemContent) ()
- (id)initWithContent:(id)content WB_CLUSTER_METHOD;
@end

@implementation WBClusterPlaceholder(WBBezelItemContent)

- (id)initWithContent:(id)content {
  if (!content) {
    return nil;
  } else if ([content isKindOfClass:[NSImage class]]) {
    return [[WBBezelItemImage alloc] initWithContent:content];
  } else if ([content isKindOfClass:[NSString class]] || [content isKindOfClass:[NSAttributedString class]]) {
    return [[WBBezelItemText alloc] initWithContent:content];
  } else if ([content isKindOfClass:[NSView class]]) {
    return [[WBBezelItemCustomView alloc] initWithContent:content];
  } else {
		SPXThrowException(NSInvalidArgumentException, @"WBBezelItem does not support content of type %@", [content class]);
  }
}

@end

#pragma mark -
@implementation WBBezelItemContent

- (id)initWithContent:(id)content {
  return [super init];
}

- (NSSize)size {
  SPXAbstractMethodException();
}

- (id)content {
  SPXAbstractMethodException();
}

@end

#pragma mark -
@implementation WBBezelItemCustomView

- (id)initWithContent:(NSView *)content {
  if (self = [super initWithFrame:NSZeroRect]) {
    wb_view = content;
    [self addSubview:wb_view];
  }
  return self;
}

- (NSSize)size {
  return [wb_view frame].size;
}

- (id)content {
  return wb_view;
}

@end

#pragma mark -
@implementation WBBezelItemImage

- (id)initWithContent:(NSImage *)image {
  NSRect frame = NSZeroRect;
  frame.size = [image size];
  NSImageView *view = [[NSImageView alloc] initWithFrame:frame];
  if (self = [super initWithContent:view]) {
    [view setImageAlignment:NSImageAlignCenter];
    [view setImageFrameStyle:NSImageFrameNone];
    [view setImageScaling:NSScaleNone];
    [view setEditable:NO];
    [view setImage:image];
  }
  [view release];
  return self;
}

- (NSSize)size {
  NSImage *img = [self content];
  return img ? [img size] : NSZeroSize;
}

- (id)content {
  return [[super content] image];
}

@end

#pragma mark -
@implementation WBBezelItemText

- (NSView *)textView {
  return [super content];
}

- (void)setText:(id)text {
  NSAttributedString *str = nil;
  if ([text isKindOfClass:[NSAttributedString class]]) {
    str = [text retain];
  } else if ([text isKindOfClass:[NSString class]]) {
    str = [[NSAttributedString alloc] initWithString:text];
  } else {
		SPXThrowException(NSInvalidArgumentException, @"Invalid content class");
  }

  [[self content] setAttributedString:[str autorelease]];

  NSRect frame = [[self textView] frame];
  frame.size = [str size];
  frame.size.width += 12;
  [[self textView] setFrameSize:frame.size];
  [self setFrameSize:[self size]];
  frame = [[self textView] frame];
  frame.origin.x = round((NSWidth([self frame]) - NSWidth(frame)) / 2);
  frame.origin.y = round((NSHeight([self frame]) - NSHeight(frame)) / 2);

  [[self textView] setFrameOrigin:frame.origin];
}

- (id)initWithContent:(id)content {
  NSTextView *view = [[NSTextView alloc] init];
  if (self = [super initWithContent:view]) {
    [self setText:content];
    [view setRichText:YES];
    [view setSelectable:NO];
    [view setDrawsBackground:NO];
  }
  [view release];
  return self;
}

- (id)content {
  return [[super content] textStorage];
}

@end
