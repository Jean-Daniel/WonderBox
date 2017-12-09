/*
 *  NSAlert+WonderBox.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAlert (UserDefaultCheckBox)
/* Application modal sheet */
// - (NSModalResponse)runSheetModalForWindow:(NSWindow *)window;

+ (NSAlert *)alertWithMessageText:(nullable NSString *)message informativeText:(NSString *)format;
+ (NSAlert *)alertWithMessageText:(nullable NSString *)message informativeTextWithFormat:(NSString *)format, ...;

  /*!
  @method
   @abstract   Add a small check box on bottom left of Alert window.
   Create a Binding between checkbox <i>value</i> and UserDefault <i>key</i>.<br />
   Usefull if you want made a "Do not Show Again" check box.
   @param      key The UserDefault Value. If nil, the binding is not created.
   */
- (void)bindSuppressionButtonToUserDefault:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
