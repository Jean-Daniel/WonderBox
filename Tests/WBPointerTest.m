/*
 *  WBPointerTest.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <GHUnit/GHUnit.h>
#import WBHEADER(WBTaggedPointer.h)

@interface WBPointerTest : GHTestCase {
  
}

@end

@implementation WBPointerTest

- (void)testMallocAlignment {
  void *ptr = malloc(1);
//  WBTaggedPointer tptr = 0;
//  WBTaggedPointerSetAddress(&tptr, ptr);
  GHAssertTrue(((intptr_t)ptr & 0xf) == 0, @"invalid pointer alignment: %x", ptr);
  free(ptr);
}

- (void)testSetGetFlags {
  void *addr = malloc(1);
  WBTaggedPointer ptr = 0;
  WBTaggedPointerSetAddress(&ptr, addr);
  
  WBTaggedPointerSetFlags(&ptr, 0x0f);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 1), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 2), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 4), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 7), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(addr == WBTaggedPointerGetAddress(ptr), @"invalid pointer adress: %x ≠ %x", addr, WBTaggedPointerGetAddress(ptr));  

  WBTaggedPointerClearFlags(&ptr, 2);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 1), @"invalid pointer flags: %x", ptr);
  GHAssertFalse(WBTaggedPointerTestFlags(ptr, 2), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 4), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerTestFlags(ptr, 5), @"invalid pointer flags: %x", ptr);  
  GHAssertFalse(WBTaggedPointerTestFlags(ptr, 7), @"invalid pointer flags: %x", ptr);
  GHAssertTrue(WBTaggedPointerGetFlags(ptr, 7) == 5, @"invalid pointer flags: %x", ptr);  
  GHAssertTrue(addr == WBTaggedPointerGetAddress(ptr), @"invalid pointer adress: %x ≠ %x", addr, WBTaggedPointerGetAddress(ptr));  
  
  WBTaggedPointerFree(ptr);
}

@end
