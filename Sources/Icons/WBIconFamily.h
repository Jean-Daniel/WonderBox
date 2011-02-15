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

#import WBHEADER(WBBase.h)

#pragma mark -
/*!
    @enum 		WBIconFamilySelector
	@abstract   Selectors are used to set icon family elements from an Image.<br />
				Read <em>setIconFamilyElements:fromImage:</em> documentation.
*/
enum {
  kWBSelectorARGB512PixelData		= 0x80000000,
  /* 256 * 256 Variant */
  kWBSelectorARGB256PixelData		= 0x40000000,
  /* Thumbnails */
  kWBSelectorThumbnail32BitData		= 0x20000000,
  kWBSelectorThumbnail8BitMask		= 0x10000000,
  /* Huge */
  kWBSelectorHuge32BitData			= 0x00000001,
  kWBSelectorHuge8BitData			= 0x00000002,
  kWBSelectorHuge4BitData			= 0x00000004,
  kWBSelectorHuge1BitData			= 0x00000008,
  kWBSelectorHuge8BitMask			= 0x00000010,
  kWBSelectorHuge1BitMask			= 0x00000020,
  /* Large */
  kWBSelectorLarge32BitData			= 0x00000100,
  kWBSelectorLarge8BitData			= 0x00000200,
  kWBSelectorLarge4BitData			= 0x00000400,
  kWBSelectorLarge1BitData			= 0x00000800,
  kWBSelectorLarge8BitMask			= 0x00001000,
  kWBSelectorLarge1BitMask			= 0x00002000,
  /* Small */
  kWBSelectorSmall32BitData			= 0x00010000,
  kWBSelectorSmall8BitData			= 0x00020000,
  kWBSelectorSmall4BitData			= 0x00040000,
  kWBSelectorSmall1BitData			= 0x00080000,
  kWBSelectorSmall8BitMask			= 0x00100000,
  kWBSelectorSmall1BitMask			= 0x00200000,
  /* Mini */
  kWBSelectorMini8BitData			= 0x01000000,
  kWBSelectorMini4BitData			= 0x02000000,
  kWBSelectorMini1BitData			= 0x04000000,
  kWBSelectorMini1BitMask			= 0x08000000,
  /* All Family */
  kWBSelectorAllThumbnail			= 0x30000000,
  kWBSelectorAllHuge				= 0x000000ff,
  kWBSelectorAllLarge				= 0x0000ff00,
  kWBSelectorAllSmall				= 0x00ff0000,
  kWBSelectorAllMini				= 0x0f000000,
  /* All New Rsrc */
  kWBSelectorAllNewThumbnails		= kWBSelectorAllThumbnail,
  kWBSelectorAllNewHuge				= kWBSelectorHuge32BitData | kWBSelectorHuge8BitMask,
  kWBSelectorAllNewLarge			= kWBSelectorLarge32BitData | kWBSelectorLarge8BitMask,
  kWBSelectorAllNewSmall			= kWBSelectorSmall32BitData | kWBSelectorSmall8BitMask,
  kWBSelectorAllNewMini				= 0x00000000,
  kWBSelectorAllNewAvailable		= kWBSelectorAllNewThumbnails | kWBSelectorAllNewHuge | kWBSelectorAllNewLarge | kWBSelectorAllNewSmall | kWBSelectorAllNewMini,
  /* All Old Rsrc */
  kWBSelectorAllOldHuge				= kWBSelectorAllHuge & ~kWBSelectorAllNewHuge,
  kWBSelectorAllOldLarge			= kWBSelectorAllLarge & ~kWBSelectorAllNewLarge,
  kWBSelectorAllOldSmall			= kWBSelectorAllSmall & ~kWBSelectorAllNewSmall,
  kWBSelectorAllOldMini				= kWBSelectorAllMini & ~kWBSelectorAllNewMini,
  kWBSelectorAllOldAvailable		= kWBSelectorAllOldHuge | kWBSelectorAllOldLarge | kWBSelectorAllOldSmall | kWBSelectorAllOldMini,
  /* All Type */
  kWBSelectorAll32BitData			= kWBSelectorARGB512PixelData | kWBSelectorARGB256PixelData | kWBSelectorThumbnail32BitData | kWBSelectorHuge32BitData | kWBSelectorLarge32BitData | kWBSelectorSmall32BitData,
  kWBSelectorAll8BitData			= kWBSelectorHuge8BitData | kWBSelectorLarge8BitData | kWBSelectorSmall8BitData | kWBSelectorMini8BitData,
  kWBSelectorAll4BitData			= kWBSelectorHuge4BitData | kWBSelectorLarge4BitData | kWBSelectorSmall4BitData | kWBSelectorMini4BitData,
  kWBSelectorAll1BitData			= kWBSelectorHuge1BitData | kWBSelectorLarge1BitData | kWBSelectorSmall1BitData | kWBSelectorMini1BitData,
  kWBSelectorAll8BitMask			= kWBSelectorThumbnail8BitMask | kWBSelectorHuge8BitMask | kWBSelectorLarge8BitMask | kWBSelectorSmall8BitMask,
  kWBSelectorAll1BitMask			= kWBSelectorHuge1BitMask | kWBSelectorLarge1BitMask | kWBSelectorSmall1BitMask | kWBSelectorMini1BitMask,
  /* All */
  kWBSelectorAllAvailable		= 0xffffffffU
};
typedef NSInteger WBIconFamilySelector;

enum {
	kHuge1BitData		= 'ich1',
	kLarge1BitData		= 'icl1',
    kSmall1BitData		= 'ics1',
	kMini1BitData		= 'icm1'
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
@interface WBIconFamily : NSObject {
  @private
  id wb_delegate;
  IconFamilyHandle wb_family;
}

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
	@param      fourByteCode
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
    @param      anImage
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
    @param      fourByteCode
    @result     Returns a new Icon family corresponding to <em>fourByteCode</em> System Icon.
*/
- (id)initWithSystemIcon:(OSType)fourByteCode;

/*!
    @method     initWithThumbnailsOfImage:
    @abstract   Initializes an IconFamily by creating its elements from a resampled NSImage.
		This methods create elements for corresponding to <em>kWBSelectorAllNewAvailable</em>,
				that is 32 bits data and 8 bits mask for each size.
    @param      image an NSImage in any format.
    @result     Returns an new Icon family.
*/
- (id)initWithThumbnailsOfImage:(NSImage *)anImage;

  /*!
    @method     initWithThumbnailsOfImage:forElements:
    @abstract
    @param      anImage
    @param      elements
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
    @param      anImage
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
    @param      elementType (description)
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
    @param      aVariantType
    @result     Returns the IconFamily that represents <em>aVariantType</em>, or nil if it does'nt exist.
*/
- (WBIconFamily *)iconFamilyVariantForType:(OSType)aVariantType;

/*!
    @method     setIconFamilyVariant:forType:
    @abstract   Set <em>aFamily</em> as variant of type <em>aVariantType</em>.
				If a variant for this type is already setted, it is replaced.
				If <em>aFamily</em> contains variants (except 'tile' variant), they are not added.
    @param      aFamily The IconFamily you want use as variant
    @param      aVariantType
    @result     Return YES if variant is setted without error.
*/
- (BOOL)setIconFamilyVariant:(WBIconFamily *)aFamily forType:(OSType)aVariantType;

/*!
    @method     removeVariant:
    @abstract   Remove variant of type <em>aVariantType</em> from the receiver.
    @param      aVariantType
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
