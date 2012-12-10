/*
 *  NSData+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/NSData+WonderBox.h>

@implementation NSData (WBHandleUtils)

+ (id)dataWithHandle:(Handle)handle {
  return [[[self alloc] initWithHandle:handle] autorelease];
}

- (id)initWithHandle:(Handle)handle {
  if (handle)  {
    self = [self initWithBytes:*handle length:GetHandleSize(handle)];
  } else {
    [self release];
    self = nil;
  }
  return self;
}

@end

@implementation NSMutableData (WBExtensions)

- (void)deleteBytesInRange:(NSRange)range {
  CFDataDeleteBytes((CFMutableDataRef)self, CFRangeMake(range.location, range.length));
}

@end
