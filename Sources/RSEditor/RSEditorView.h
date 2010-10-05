/*
 *  RSEditorView.h
 *  RichSubtitle
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import WBHEADER(WBBase.h)

WB_CLASS_EXPORT
@interface RSEditorView : NSObject {
@private
	IBOutlet NSView *ibView;
	IBOutlet NSTextField *ibWidth;

	CGFloat rs_swidth;
}

- (NSView *)view;

- (IBAction)changeStrokeWidth:(id)sender;
- (IBAction)changeStrokeColor:(id)sender;

- (void)updateAttributes:(NSTextView *)sender;

@end

WB_CLASS_EXPORT
@interface RSTextView : NSTextView {
@private

}

@end

WB_CLASS_EXPORT
@interface RSEditorEffectView : NSView {
@private
	NSColor *rs_color;
}

@end
