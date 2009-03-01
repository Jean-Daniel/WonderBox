/*
 *  WBOutlineView.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */
/*!
    @header WBOutlineView
    @abstract   (description)
    @discussion (description)
*/

WB_CLASS_EXPORT
@interface WBOutlineView : NSOutlineView {
@private
  struct _wb_ovFlags {
    unsigned int edit:1;
    unsigned int reserved:31;
  } wb_ovFlags;
  NSHashTable *wb_noPadding;
}

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

@interface NSObject (WBOutlineViewDelegate)
- (void)deleteSelectionInOutlineView:(NSOutlineView *)aView;
- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForRow:(NSInteger)row;
@end
