/*
 *  WBAppKitExtensions.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBAppKitExtensions.h)
#import WBHEADER(WBFunctions.h)

#pragma mark -
@implementation NSArrayController (WBExtensions)

- (NSUInteger)count {
  return [[self arrangedObjects] count];
}

- (NSEnumerator *)objectEnumerator {
  return [[self content] objectEnumerator];
}

- (id)objectAtIndex:(NSUInteger)rowIndex {
  return [[self arrangedObjects] objectAtIndex:rowIndex];
}

- (id)selectedObject {
  id selection = [self selectedObjects];
  if ([selection count]) {
    return [selection objectAtIndex:0];
  }
  return nil;
}

- (BOOL)setSelectedObject:(id)object {
  return [self setSelectedObjects:[NSArray arrayWithObject:object]];
}

- (void)deleteSelection {
  [self removeObjects:[self selectedObjects]];
}

- (void)removeAllObjects {
  [self removeObjects:[self content]];
}

@end

#pragma mark -
@implementation NSImage (WBImageNamedInBundle)

+ (id)imageNamed:(NSString *)name inBundleWithIdentifier:(NSBundle *)bundle {
  NSImage *image = nil;
  if (name) {
    /* First check internal cache */
    image = [NSImage imageNamed:name];
    if (!image) {
      /* Then search bundle resource */
      NSString *path = bundle ? [bundle pathForImageResource:name] : nil;
      image = path ? [[NSImage alloc] initWithContentsOfFile:path] : nil;
      if (image) {
        [image setName:name];
        [image autorelease];
      } else {
        DLog(@"Unable to find image %@ in bundle %@", name, [bundle bundleIdentifier]);
      }
    }
  }
  return image;
}

+ (id)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
  return [self imageNamed:name inBundleWithIdentifier:bundle];
}

@end

#pragma mark -
@implementation NSAlert (WBUserDefaultCheckBox)

- (NSButton *)addUserDefaultCheckBoxWithTitle:(NSString *)title andKey:(NSString *)key {
  NSParameterAssert(nil != title);
  
  NSButton *box = [[NSButton alloc] initWithFrame:NSMakeRect(20, 22, 16, 150)];
  /* Set Small Size */
  [[box cell] setControlSize:NSSmallControlSize];
  [box setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
  /* Configure Check Box */
  [box setButtonType:NSSwitchButton];
  [box setTitle:title];
  [box sizeToFit];
  
  /* Bind CheckBox value to User Defaults */
  if (key) {
    [box bind:@"value"    
     toObject:[NSUserDefaultsController sharedUserDefaultsController]
  withKeyPath:[@"values." stringByAppendingString:key]
      options:nil];
  }
  /* Add Check Box to Alert Window */
  [[[self window] contentView] addSubview:box];
  [box release];
  return box;
}

- (NSInteger)runSheetModalForWindow:(NSWindow *)window {
  [self beginSheetModalForWindow:window
                   modalDelegate:self
                  didEndSelector:@selector(wb_alertDidEnd:returnCode:contextInfo:)
                     contextInfo:nil];
  return [NSApp runModalForWindow:[self window]];
}

- (void)wb_alertDidEnd:(NSAlert *)alert returnCode:(NSUInteger)returnCode contextInfo:(void *)contextInfo {
  [NSApp stopModalWithCode:returnCode];
}

@end

#pragma mark -
@implementation NSImageView (WBSimpleImageView)
- (id)initWithImage:(NSImage *)image {
  if (self = [super init]) {
    [self setImage:image];
    if (image)
      [self setFrameSize:[image size]];
    [self setImageScaling:NSScaleNone];
    [self setImageFrameStyle:NSImageFrameNone];
    [self setImageAlignment:NSImageAlignCenter];
  }
  return self;
}
@end

#pragma mark -
@implementation NSButton (WBImageButton)
- (id)initWithFrame:(NSRect)frame image:(NSImage *)anImage alternateImage:(NSImage *)altImage {
  if (self = [super initWithFrame:frame]) {
    [self setBordered:NO];
    [self setImage:anImage];
    [self setAlternateImage:altImage];
    [self setImagePosition:NSImageOnly];
    [self setFocusRingType:NSFocusRingTypeNone];
    [self setButtonType:NSMomentaryChangeButton];
  }
  return self;
}
@end

#pragma mark -
@implementation NSTabView (WBExtensions)
- (NSInteger)indexOfSelectedTabViewItem {
  return [self indexOfTabViewItem:[self selectedTabViewItem]]; 
}
@end

#pragma mark -
@implementation NSText (WBExtensions)
- (void)setEnabled:(BOOL)enabled {
  [self setEditable:enabled];
  [self setSelectable:enabled];
  [self setTextColor: enabled ? [NSColor textColor] : [NSColor disabledControlTextColor]];
}
@end

#pragma mark -
@implementation NSTableView (WBExtensions)
- (NSTableColumn *)columnAtIndex:(NSUInteger)idx {
  return [[self tableColumns] objectAtIndex:idx];
}
@end

#pragma mark -
@implementation NSColor (WBHexdecimal)

+ (id)colorWithDeviceHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha {
  return [self colorWithDeviceRed:red/255. green:green/255. blue:blue/255. alpha:alpha/255.];
}

+ (id)colorWithCalibratedHexaRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha {
  return [self colorWithCalibratedRed:red/255. green:green/255. blue:blue/255. alpha:alpha/255.];
}

@end

#pragma mark -
@implementation NSUserDefaults(WBUserDefaultsColor)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey {
  NSData *theData = [NSKeyedArchiver archivedDataWithRootObject:aColor];
  [self setObject:theData forKey:aKey];
}

- (NSColor *)colorForKey:(NSString *)aKey {
  NSColor *theColor = nil;
  NSData *theData = [self dataForKey:aKey];
  if (theData != nil)
    theColor = (NSColor *)[NSKeyedUnarchiver unarchiveObjectWithData:theData];
  return theColor;
}

@end

#pragma mark -
@implementation NSFileWrapper (WBExtensions)

- (id)propertyListForFilename:(NSString *)filename {
  return [self propertyListForFilename:filename mutabilityOption:NSPropertyListImmutable];
}

- (id)propertyListForFilename:(NSString *)filename mutabilityOption:(NSPropertyListMutabilityOptions)opt {
  NSData *data = [[[self fileWrappers] objectForKey:filename] regularFileContents];
  if (data) {
    return [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
  }
  return nil;
}

@end

#pragma mark -
@implementation NSTableView (WBContextualMenuExtension)

- (BOOL)wb_handleMenuForEvent:(NSEvent *)theEvent row:(NSInteger)row {
  if (row != -1) {
    if ([theEvent modifierFlags] & NSCommandKeyMask) {
      //      if ([self isRowSelected:row]) {
      //        [self deselectRow:row];
      //        // Deselect do not trigger contextual menu
      //        return NO;
      //      } else
      if ([self numberOfSelectedRows] == 0 || [self allowsMultipleSelection]) {
        [self selectRow:row byExtendingSelection:YES];
      } else {
        return NO;
      }
    } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
      if (![self isRowSelected:row]) {
        if ([self numberOfSelectedRows] == 0) {
          // nothing
        } else if (![self allowsMultipleSelection]) {
          // Deselect do not trigger contextual menu
          return NO;
        } else {
          // Should be 'select all rows between nearest selected and row'
          NSInteger last = [self selectedRow];
          if (last != -1) {
            NSRange range;
            if (last < row) {
              range = NSMakeRange(last, row - last + 1);
            } else {
              range = NSMakeRange(row, last - row);
            }
            [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:range] byExtendingSelection:YES];
          }
        }
      }
    } else {
      if (![self isRowSelected:row]) {
        [self selectRow:row byExtendingSelection:NO];
      }
    }
  }
  [self displayIfNeeded];
  return YES;
}

@end
