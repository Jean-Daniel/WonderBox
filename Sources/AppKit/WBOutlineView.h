/*
 *  WBOutlineView.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
 @header WBOutlineView
 @abstract   (description)
 @discussion (description)
 */

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@protocol WBOutlineViewDelegate;
#endif

WB_CLASS_EXPORT
@interface WBOutlineView : NSOutlineView {
@private
  struct _wb_ovFlags {
    unsigned int edit:1;
    unsigned int drawOutline:1;
    unsigned int reserved:30;
  } wb_ovFlags;
  NSHashTable *wb_noPadding;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (id<WBOutlineViewDelegate>)delegate;
- (void)setDelegate:(id<WBOutlineViewDelegate>)aDelegate;
#endif

- (IBAction)delete:(id)sender;
/*!
 @method		keyDown:
 @abstract	informe the delegate if delete backward or forward is pressed 
 and send target doubleAction message if Enter is pressed.
 @param 		theEvent	
 */
- (void)keyDown:(NSEvent *)theEvent;
- (void)editColumn:(NSInteger)column item:(id)anItem;

- (void)setPadding:(BOOL)flag forTableColumn:(NSString *)columnIdentifier;

/* Should edit next cell after cell edition */
- (void)setContinueEditing:(BOOL)flag;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
@protocol WBOutlineViewDelegate <NSOutlineViewDelegate>
@optional
#else
@interface NSObject (WBOutlineViewDelegate)
#endif

- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView;
// Used for UI validation
- (BOOL)canDeleteSelectionInOutlineView:(NSOutlineView *)aView;

// returns NO to prevent outline cell drawing. Used in Source List.
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldDrawOutlineCellAtRow:(NSInteger)row;

@end

