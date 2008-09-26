/*
 *  WBAppKitExtensions.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */
/*!
    @header WBAppKitExtensions
    @abstract   (description)
    @discussion (description)
*/

#pragma mark -
@interface NSImage (WBImageNamedInBundle)
/*!
@method     imageNamed:inBundle:
 @abstract   Act as +imageNamed: method but search in a specified Bundle instead of searching mainBundle only.
 @param      name The name of the image you want find.
 @param      bundle The bundle containing this image.
 @result     Returns the image if find one, or nil if no image were found.
 */
+ (id)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
+ (id)imageNamed:(NSString *)name inBundleWithIdentifier:(NSBundle *)bundle;
@end

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

@interface NSButton (WBImageButton)
- (id)initWithFrame:(NSRect)frame image:(NSImage *)anImage alternateImage:(NSImage *)altImage;
@end

@interface NSImageView (WBSimpleImageView)
/*!
@method
 @abstract Create and configure an NSImageView that just draws an image.
 */
- (id)initWithImage:(NSImage *)image;
@end

#pragma mark -
@interface NSTabView (WBExtensions)
- (NSInteger)indexOfSelectedTabViewItem;
@end

#pragma mark -
@interface NSTableView (WBExtensions)
- (NSTableColumn *)columnAtIndex:(NSUInteger)idx;
@end

#pragma mark -
@interface NSText (WBExtensions)
- (void)setEnabled:(BOOL)enabled;
@end

#pragma mark -
@interface NSArrayController (WBExtensions)

- (NSUInteger)count;

- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(NSUInteger)rowIndex;

- (id)selectedObject;
- (BOOL)setSelectedObject:(id)object;

- (void)deleteSelection;
- (void)removeAllObjects;

@end

#pragma mark -
@interface NSColor (WBHexdecimal)

+ (id)colorWithDeviceHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha;
+ (id)colorWithCalibratedHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha;

@end

#pragma mark -
@interface NSUserDefaults (WBUserDefaultsColor)

- (NSColor *)colorForKey:(NSString *)aKey;
- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey;

@end

#pragma mark -
@interface NSFileWrapper (WBExtensions)

- (id)propertyListForFilename:(NSString *)filename; // NSPropertyListImmutable 
- (id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt;

@end

#pragma mark -
#pragma mark Internal
@interface NSTableView (WBContextualMenuExtension)
- (BOOL)wb_handleMenuForEvent:(NSEvent *)theEvent row:(NSInteger)row;
@end
