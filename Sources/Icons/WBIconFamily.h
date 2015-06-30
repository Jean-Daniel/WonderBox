/*
 *  WBIconFamily.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBIconFamily
    @abstract   (description)
    @discussion (description)
*/

#import <WonderBox/WBBase.h>

#pragma mark -
/*!
    @enum 		WBIconFamilySelector
	@abstract   Selectors are used to set icon family elements from an Image.<br />
				Read <em>setIconFamilyElements:fromImage:</em> documentation.
*/
typedef NS_OPTIONS(NSInteger, WBIconFamilySelector) {
  /* Small (16 x 16) */
  kWBSelector16Data			= 1 << 0,
  kWBSelector16Mask			= 1 << 1,

  /* Large (32 x 32) */
  kWBSelector32Data			= 1 << 2,
  kWBSelector32Mask			= 1 << 3,

  /* Huge (48 x 48) */
  kWBSelector48Data			= 1 << 4,
  kWBSelector48Mask			= 1 << 5,

  /* Thumbnails (128 x 128) */
  kWBSelector128Data		= 1 << 6,
  kWBSelector128Mask		= 1 << 7,

  kWBSelector256ARGB		= 1 << 8,
  kWBSelector512ARGB		= 1 << 9,
  kWBSelector1024ARGB	  = 1 << 10,

  /* All Family */
  kWBSelector16          = kWBSelector16Data | kWBSelector16Mask,
  kWBSelector32          = kWBSelector32Data | kWBSelector32Mask,
  kWBSelector48          = kWBSelector48Data | kWBSelector48Mask,
  kWBSelector128         = kWBSelector128Data | kWBSelector128Mask,

  /* All New Rsrc */
  kWBSelectorAll         = kWBSelector16 | kWBSelector32 | kWBSelector48 | kWBSelector128 | kWBSelector256ARGB | kWBSelector512ARGB | kWBSelector1024ARGB,
  /* All Type */
  kWBSelectorAllData			= kWBSelector16Data | kWBSelector32Data | kWBSelector48Data | kWBSelector128Data,
  kWBSelectorAllMask			= kWBSelector16Mask | kWBSelector32Mask | kWBSelector48Mask | kWBSelector128Mask,
};

/*!
    @class		 WBIconFamily
    @abstract    A Powerfull carbon IconFamily Wrapper. This class can convert every types of images (1 to 5 channels, interleaved or planar&#8230;)
				 into Mac OS X icons. It handles icon variants (Mac OS X.3 only uses <em>kOpenDropIconVariant</em>).
    @discussion  This wrapper use low-level resampling functions so you can use it in command-line tools. You don't have to create off-screen window.
                <dl>
				 <dt><em>kTileIconVariant</em></dt>
				 <dd>Define Tile Icon Representation. You can set one tile per variant.</dd>
				<dt><em>kRolloverIconVariant</em></dt>
				 <dd>Define Rollover Icon Variant.</dd>
				<dt><em>kDropIconVariant</em></dt>
				 <dd>Define Drop Icon Variant.</dd>
				<dt><em>kOpenIconVariant</em></dt>
				 <dd>Define Open Icon Variant.</dd>
				<dt><em>kOpenDropIconVariant</em></dt>
				 <dd>Define Open Drop Icon Variant. This variant is display when you drop an item over a folder or an application for exemple.</dd>
				</dl>
*/
WB_OBJC_EXPORT
@interface WBIconFamily : NSObject

#pragma mark Convenients Initializers
/*!
    @method     iconFamily
    @abstract   Intitialize and returns a new empty icon family.
    @result     A new Empty Icon family.
*/
+ (id)iconFamily;

/*!
    @method     iconFamilyWithContentsOfFile:
	@abstract   Initializes an IconFamily by loading the contents of an .icns file.
	@param      path The full path of an 'icns' file.
	@result     Returns an new Icon family.
*/
+ (id)iconFamilyWithContentsOfFile:(NSString*)path;

/*!
    @method     iconFamilyWithIconAtPath:
	@abstract   Initializes an IconFamily by loading the Finder icon that's assigned to a file.
	@param      path The full path of a file or folder.
	@result     Returns an new Icon family.
*/
+ (id)iconFamilyWithIconAtPath:(NSString*)path;
/*!
    @method     iconFamilyWithIconFamilyHandle:
	@abstract   Initializes an IconFamily from an existing Carbon IconFamilyHandle.
	@param      anIconFamily A Carbon IconFamilyHandle
	@result     Returns an new Icon family.
*/
+ (id)iconFamilyWithIconFamilyHandle:(IconFamilyHandle)anIconFamily;

/*!
    @method     iconFamilyWithSystemIcon:
	@abstract   Initializes an IconFamily by referencing a standard system icon.
	@result     Returns a new Icon family corresponding to <em>fourByteCode</em> System Icon.
*/
+ (id)iconFamilyWithSystemIcon:(OSType)fourByteCode;

/*!
    @method     iconFamilyWithThumbnailsOfImage:
	@abstract   Initializes an IconFamily by creating its elements from a resampled NSImage.
				This methods create elements for corresponding to <em>kWBSelectorAllNewAvailable</em>,
				that is 32 bits data and 8 bits mask for each size.
	@param      anImage an NSImage in any format.
	@result     Returns an new Icon family.
*/
+ (id)iconFamilyWithThumbnailsOfImage:(NSImage*)anImage;

  /*!
    @method     iconFamilyWithThumbnailsOfImage:forElements:
    @abstract   Create an new Icon Family, and create <em>elements</em> with contents of <em>anImage</em>.
    @param      elements The elements you want to create.
    @result     Returns an new Icon family.
*/
+ (id)iconFamilyWithThumbnailsOfImage:(NSImage*)anImage forElements:(WBIconFamilySelector)elements;

#pragma mark -
#pragma mark Initializers
/*!
    @method     init
    @abstract   Initializes as a new, empty IconFamily.  This is IconFamily's designated initializer method.
    @result     Returns an new empty Icon Family.
*/
- (id)init;

/*!
    @method     initWithContentsOfFile:
    @abstract   Initializes an IconFamily by loading the contents of an .icns file.
    @param      path The full path of an 'icns' file.
    @result     Returns an new Icon family.
*/
- (id)initWithContentsOfFile:(NSString *)path;

/*!
    @method     initWithIconFamilyHandle:
    @abstract   Initializes an IconFamily from an existing Carbon IconFamilyHandle.
    @param      newIconFamily A Carbon IconFamilyHandle
    @result     Returns an new Icon family.
*/
- (id)initWithIconFamilyHandle:(IconFamilyHandle)newIconFamily;


/*!
    @method     initWithIconOfFile:
    @abstract   Initializes an IconFamily by loading the Finder icon that's assigned to a file.
    @param      path The full path of a file or folder.
    @result     Returns an new Icon family.
*/
- (id)initWithIconAtPath:(NSString*)path;

/*!
    @method     initWithSystemIcon:
    @abstract   Initializes an IconFamily by referencing a standard system icon.
    @result     Returns a new Icon family corresponding to <em>fourByteCode</em> System Icon.
*/
- (id)initWithSystemIcon:(OSType)fourByteCode;

/*!
    @method     initWithThumbnailsOfImage:
    @abstract   Initializes an IconFamily by creating its elements from a resampled NSImage.
		This methods create elements for corresponding to <em>kWBSelectorAllNewAvailable</em>,
				that is 32 bits data and 8 bits mask for each size.
    @param      anImage an NSImage in any format.
    @result     Returns an new Icon family.
*/
- (id)initWithThumbnailsOfImage:(NSImage *)anImage;

  /*!
    @method     initWithThumbnailsOfImage:forElements:
    @result     Returns an new Icon family.
*/
- (id)initWithThumbnailsOfImage:(NSImage*)anImage forElements:(WBIconFamilySelector)elements;
#pragma mark -

/*!
    @method     familyHandle
    @abstract   Returns the icon family Handle used by the recevier.
*/
- (IconFamilyHandle)familyHandle;
/*!
    @method     setFamilyHandle:
    @abstract   Sets receiver IconFamilyHandle to <em>newFamilyHandle</em>.<br />
				Receiver copy <em>newFamilyHandle</em>, so you can safely dispose it after calling this method.
    @param      newIconFamily A Carbon IconFamilyHandle.
*/
- (void)setFamilyHandle:(IconFamilyHandle)newIconFamily;

/*!
    @method     writeToFile:
    @abstract   Writes the icon family to an .icns file.
    @param      path The path of destination file.
    @result     Returns YES if icon wrote without error.
*/
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag;

#pragma mark -
#pragma mark Representations manipulation

/*!
    @method     setIconFamilyElement:fromData:
    @abstract   Set data for an element. If you don't know icns data format, you can prefere use
				<em>setIconFamilyElements:fromImage:</em>.
    @param      anElement An element type
    @param      data Data into format corresponding to format define for anElement.
    @result     Returns YES if element is setted without error.
*/
- (BOOL)setIconFamilyElement:(OSType)anElement fromData:(NSData *)data;

/*!
    @method     setIconFamilyElement:fromImage:
    @abstract   Create and set icon element to <em>anImage</em> representation.
    @param      anElement An element type.
    @result     Returns YES if element is setted without error.
*/
- (BOOL)setIconFamilyElement:(OSType)anElement fromImage:(NSImage *)anImage;

/*!
    @method     setIconFamilyElement:fromBitmap:
	@abstract   Sets the image data for one of the icon family's elements from an
				NSBitmapImageRep. The <em>anElement</em> parameter must be one of the icon
				family element types listed below. The <em>bitmap</em> must have 8 bits
				per sample.
	@discussion This method set only one element. It is more efficient to use <em>setIconFamilyElements:fromImage:</em>
				to set more than one element, because image is resampled only one times per size.
    @param      anElement An element type.
    @param      bitmap A bitmap image representation with size corresponding to <em>anElement</em> size.
    @result     Returns YES if element is setted without error.
*/
- (BOOL)setIconFamilyElement:(OSType)anElement fromBitmap:(NSBitmapImageRep *)bitmap;

  /*!
    @method     setIconFamilyElements:fromImage:
    @abstract   (brief description)
    @discussion This methods create one bitmap resized representation per Elements size, so it is
				more efficient to use it instead of repeatly call setIconFamilyElement:fromBitmap:.
    @param      selector A selector that define which elements you want to set.
    @param      anImage An image in any format.
*/
- (NSUInteger)setIconFamilyElements:(WBIconFamilySelector)selector fromImage:(NSImage *)anImage;

/*!
    @method     bitmapImageRepWithAlphaForIconFamilyElement:
	@abstract   Gets the image data for one of the icon family's elements as a new, 32-bit
				RGBA NSBitmapImageRep
	@discussion Gets the image data for one of the icon family's elements as a new, 32-bit
				RGBA NSBitmapImageRep.  The specified elementType should be one of
				kThumbnail32BitData, kLarge32BitData, or kSmall32BitData.<br /><br />
				The returned NSBitmapImageRep will have the corresponding 8-bit mask data
				in its alpha channel, or a fully opaque alpha channel if the icon family
				has no 8-bit mask data for the specified alpha channel.
    @param      anElement (description)
	@result     Returns nil if the requested element cannot be retrieved
				(e.g. if the icon family has no such 32BitData element).
*/
- (NSData *)dataForIconFamilyElement:(OSType)anElement;

/*!
	@method     bitmapImageRepForIconFamilyElement:
	@abstract   Gets the image data for one of the icon family's elements as a new
				NSBitmapImageRep with 8 bits, or 24 bits per sample depending element you request.<br />
				If you want a bitmap representation with alpha channel, use <em>bitmapForIconFamilyElement:withMask:</em>
				instead of this method.<br />
				<strong>Note:</strong>This method will return a planar bitmap representation.
	@param      anElement An element type.
	@result     A new NSBitmapImageRep representing the requested element.
 */
- (NSBitmapImageRep *)bitmapForIconFamilyElement:(OSType)anElement;
/*!
    @method     bitmapForIconFamilyElement:withMask:
	@abstract   Gets the image data for one of the icon family's elements as a new
				NSBitmapImageRep with 8 bits, 24 bits, or 32 bits per sample depending
				element you request and <em>useAlpha</em> parameter.<br />
    @discussion useAlpha is ignore for mask elements. if you request a 32 elements, alpha
				channel is the corresponding 8 bits mask if one exists. If you request 8 bit or 4 bit
				data element, alpha channel will be corresponding 1 bit mask if one exists.<br />
				<strong>Note:</strong>This method will return a planar bitmap representation.
    @param      anElement (description)
    @param      useAlpha If you want an image representation with an alpha channel corresponding to
				anElement Mask. Use 8 bit mask for 8 bit data, else use 1 bit mask.
    @result     Returns a new NSBitmapImageRep representing requested element if it exists, nil otherwise.
*/
- (NSBitmapImageRep *)bitmapForIconFamilyElement:(OSType)anElement withMask:(BOOL)useAlpha;

/*!
    @method     imageWithAllRepresentations
    @abstract   Creates and returns an NSImage that contains the icon family's various elements as its NSImageReps.<br />
				This method has the same effect than writing this icon into an icns file, and then creating an image with
				contents of this file.
    @result     Returns an NSImage contening differents representations of this icon.
*/
- (NSImage *)imageWithAllRepresentations;

#pragma mark -
#pragma mark Variants manipulation

/*!
    @method     variantsTypes
    @abstract   Return the list of presents variants into the receiver.
    @result     Return an NSArray contening NSNumber that represents variant type.
*/
- (NSArray *)variantsTypes;

/*!
    @method     containsVariant:
    @abstract   Returns YES if the receiver contains a variant ot type <em>aVariant</em>
    @param      aVariantType A variant type.
    @result     Returns YES if the receiver contains a variant ot type <em>aVariant</em>
*/
- (BOOL)containsVariant:(OSType)aVariantType;

/*!
    @method     iconFamilyVariantForType:
    @abstract   Extracts the IconFamily corresponding to <em>aVariantType</em>.
    @result     Returns the IconFamily that represents <em>aVariantType</em>, or nil if it does'nt exist.
*/
- (WBIconFamily *)iconFamilyVariantForType:(OSType)aVariantType;

/*!
    @method     setIconFamilyVariant:forType:
    @abstract   Set <em>aFamily</em> as variant of type <em>aVariantType</em>.
				If a variant for this type is already setted, it is replaced.
				If <em>aFamily</em> contains variants (except 'tile' variant), they are not added.
    @param      aFamily The IconFamily you want use as variant
    @result     Return YES if variant is setted without error.
*/
- (BOOL)setIconFamilyVariant:(WBIconFamily *)aFamily forType:(OSType)aVariantType;

/*!
    @method     removeVariant:
    @abstract   Remove variant of type <em>aVariantType</em> from the receiver.
    @result     Return YES if variant is removed without error, or if the receiver doesn't contains this variant.
*/
- (BOOL)removeVariant:(OSType)aVariantType;

#pragma mark -
#pragma mark Set as Custom Icon
/*!
	@method     setAsCustomIconAtPath:
	@abstract   Writes the icon family to the resource fork of the specified file or folder
				as its kCustomIconResource, and sets the necessary Finder bits so the
				icon will be displayed for the file in Finder views.
	@param      path A path. This methods works with files and folders.
	@result     Return YES if icon is correctly setted.
*/
- (BOOL)setAsCustomIconAtPath:(NSString*)path;
- (BOOL)setAsCustomIconAtPath:(NSString*)path withCompatibility:(BOOL)compat;

/*!
    @method     setAsCustomIconForFile:
    @abstract   Writes the icon family to the resource fork of the specified file as its
				kCustomIconResource, and sets the necessary Finder bits so the icon will
				be displayed for the file in Finder views.
    @param      path A file path. This methods wouldn't works with folder.
    @result     Return YES if icon is correctly setted.
*/
- (BOOL)setAsCustomIconForFile:(NSString*)path;
- (BOOL)setAsCustomIconForFile:(NSString*)path withCompatibility:(BOOL)compat;

/*!
    @method     setAsCustomIconForDirectory:
	@abstract   Writes the icon family into icon hidden file of folder at <em>path</em>,
				and sets the necessary Finder bits so the icon will	be displayed for the
				file in Finder views. Works also with Volumes root directory.
    @param      path A folder path. This methods wouldn't works with files.
    @result     Return YES if icon is correctly setted.
*/
- (BOOL)setAsCustomIconForDirectory:(NSString*)path;
- (BOOL)setAsCustomIconForDirectory:(NSString*)path withCompatibility:(BOOL)compat;

#pragma mark -
/*!
    @method     removeCustomIconFromFile:
    @abstract   Removes the custom icon (if any) from the specified file's resource fork,
				and clears the necessary Finder bits for the file. This methods works also
				with folders.
    @param      path The full path of file you want to remove icon.
    @result     Returns YES if no error.
*/
+ (BOOL)removeCustomIconAtPath:(NSString *)path;

#pragma mark -
#pragma mark Image Scaling Method
- (id)delegate;
- (void)setDelegate:(id)delegate;

- (NSBitmapImageRep *)scaleImage:(NSImage *)anImage toSize:(NSSize)size;

@end

@interface NSObject (WBIconFamilyDelegate)

/* Return nil to use default value */
- (NSBitmapImageRep *)iconFamily:(WBIconFamily *)aFamily shouldScaleImage:(NSImage *)anImage toSize:(NSSize)size;

@end
