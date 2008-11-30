/*
 *  NSAlert+WonderBox.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#pragma mark -
@interface NSAlert (UserDefaultCheckBox)
/* Application modal sheet */
- (NSInteger)runSheetModalForWindow:(NSWindow *)window;

  /*!
  @method
   @abstract   Add a small check box on bottom left of Alert window.
   Create a Binding between checkbox <i>value</i> and UserDefault <i>key</i>.<br />
   Usefull if you want made a "Do not Show Again" check box.
   @param      title The title of the checkbox.
   @param      key The UserDefault Value. If nil, the binding is not created.
   @result		Returns the check box.
   */
- (NSButton *)addUserDefaultCheckBoxWithTitle:(NSString *)title andKey:(NSString *)key;
@end
