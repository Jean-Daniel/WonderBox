/*
 *  WBBezelItemContent.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBBezelItemContent.h"

@interface WBBezelItemCustomView : WBBezelItemContent {
@private
  NSView *wb_view;
}

- (id)initWithView:(NSView *)content;

@end

@interface WBBezelItemImage : WBBezelItemCustomView {
@private
  //NSImage *wb_image;
}

- (id)initWithImage:(NSImage *)content;

@end

@interface WBBezelItemText : WBBezelItemCustomView {
@private
  //NSAttributedString *wb_text;
}

- (id)initWithString:(NSString *)content;
- (id)initWithAttributedString:(NSAttributedString *)content;

@property(nonatomic, readonly) NSTextView *textView;

@end

#pragma mark -
@implementation WBBezelItemContent

+ (instancetype)itemWithContent:(id)content {
  if (!content) {
    return nil;
  } else if ([content isKindOfClass:[NSImage class]]) {
    return [[[WBBezelItemImage alloc] initWithImage:content] autorelease];
  } else if ([content isKindOfClass:[NSString class]]) {
    return [[[WBBezelItemText alloc] initWithString:content] autorelease];
  } else if ([content isKindOfClass:[NSAttributedString class]]) {
    return [[[WBBezelItemText alloc] initWithAttributedString:content] autorelease];
  } else if ([content isKindOfClass:[NSView class]]) {
    return [[[WBBezelItemCustomView alloc] initWithView:content] autorelease];
  } else {
    SPXThrowException(NSInvalidArgumentException, @"WBBezelItem does not support content of type %@", [content class]);
  }
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

- (instancetype)initWithView:(NSView *)content {
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

- (instancetype)initWithImage:(NSImage *)image {
  NSRect frame = NSZeroRect;
  frame.size = [image size];
  NSImageView *view = [[NSImageView alloc] initWithFrame:frame];
  if (self = [super initWithView:view]) {
    [view setImageAlignment:NSImageAlignCenter];
    [view setImageFrameStyle:NSImageFrameNone];
    [view setImageScaling:NSScaleNone];
    [view setEditable:NO];
    [view setImage:image];
  }
  [view release];
  return self;
}

- (id)content {
  return [[super content] image];
}

- (NSSize)size {
  NSImage *img = [self content];
  return img ? [img size] : NSZeroSize;
}

@end

#pragma mark -
@implementation WBBezelItemText

- (instancetype)initWithString:(NSString *)content {
  return [self initWithAttributedString:[[[NSAttributedString alloc] initWithString:content] autorelease]];
}

- (instancetype)initWithAttributedString:(NSAttributedString *)content {
  NSTextView *view = [[NSTextView alloc] init];
  if (self = [super initWithView:view]) {
    [self setText:content];
    [view setRichText:YES];
    [view setSelectable:NO];
    [view setDrawsBackground:NO];
  }
  [view release];
  return self;
}

- (id)content {
  return [self.textView textStorage];
}

- (NSTextView *)textView {
  return [super content];
}

- (void)setText:(NSAttributedString *)text {
  [self.textView.textStorage setAttributedString:text];

  NSRect frame = [[self textView] frame];
  frame.size = [text size];
  frame.size.width += 12;
  [[self textView] setFrameSize:frame.size];
  [self setFrameSize:[self size]];
  frame = [[self textView] frame];
  frame.origin.x = round((NSWidth([self frame]) - NSWidth(frame)) / 2);
  frame.origin.y = round((NSHeight([self frame]) - NSHeight(frame)) / 2);

  [[self textView] setFrameOrigin:frame.origin];
}

@end
