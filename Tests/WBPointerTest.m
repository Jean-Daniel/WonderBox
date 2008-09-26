//
//  WBPointerTest.m
//  WonderBox
//
//  Created by Jean-Daniel Dupas on 22/06/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "WBPointerTest.h"
#import WBHEADER(WBTaggedPointer.h)

@implementation WBPointerTest

- (void)testMallocAlignment {
  void *ptr = malloc(1);
//  WBTaggedPointer tptr = 0;
//  WBTaggedPointerSetAddress(&tptr, ptr);
  STAssertTrue(((intptr_t)ptr & 0xf) == 0, @"invalid pointer alignment: %x", ptr);
  free(ptr);
}

- (void)testSetGetFlags {
  void *addr = malloc(1);
  WBTaggedPointer ptr = 0;
  WBTaggedPointerSetAddress(&ptr, addr);
  
  WBTaggedPointerSetFlags(&ptr, 0x0f);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 1), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 2), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 4), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 7), @"invalid pointer flags: %x", ptr);
  STAssertTrue(addr == WBTaggedPointerGetAddress(ptr), @"invalid pointer adress: %x ≠ %x", addr, WBTaggedPointerGetAddress(ptr));  

  WBTaggedPointerClearFlags(&ptr, 2);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 1), @"invalid pointer flags: %x", ptr);
  STAssertFalse(WBTaggedPointerTestFlags(ptr, 2), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 4), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerTestFlags(ptr, 5), @"invalid pointer flags: %x", ptr);  
  STAssertFalse(WBTaggedPointerTestFlags(ptr, 7), @"invalid pointer flags: %x", ptr);
  STAssertTrue(WBTaggedPointerGetFlags(ptr, 7) == 5, @"invalid pointer flags: %x", ptr);  
  STAssertTrue(addr == WBTaggedPointerGetAddress(ptr), @"invalid pointer adress: %x ≠ %x", addr, WBTaggedPointerGetAddress(ptr));  
  
  free(ptr);
}

@end
