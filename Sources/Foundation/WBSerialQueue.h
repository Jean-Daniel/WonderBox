/*
 *  WBSerialQueue.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

WB_OBJC_EXPORT
@interface WBSerialQueue : NSObject {
@private

}

//- (void)addOperation:(NSOperation *)op;
//- (void)addOperation:(NSOperation *)op waitUntilFinished:(BOOL)shouldWait;

- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg;
- (void)addOperationWithTarget:(id)target selector:(SEL)sel object:(id)arg waitUntilFinished:(BOOL)shouldWait;

@end
