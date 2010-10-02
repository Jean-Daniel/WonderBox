/*
 *  RSEditorView.m
 *  RichSubtitle
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import WBHEADER(RSEditorView.h)

@implementation RSEditorEffectView

- (void)changeColor:(id)sender {
	rs_color = [sender color];
	[NSApp sendAction:@selector(changeAttributes:) to:nil from:self];
	rs_color = nil;
}

- (NSDictionary *)convertAttributes:(NSDictionary *)attributes {
	NSMutableDictionary *dict = nil;
	if (rs_color) {
		NSColor *previous = [attributes objectForKey:NSStrokeColorAttributeName];
		if (!previous || ![rs_color isEqualTo:previous]) {
			dict = [attributes mutableCopy];
			[dict setObject:rs_color forKey:NSStrokeColorAttributeName];
		}
	}	else if ([attributes objectForKey:NSStrokeColorAttributeName]) {
		dict = [attributes mutableCopy];
		[dict removeObjectForKey:NSStrokeColorAttributeName];
	}
	return dict ? [dict autorelease] : attributes;
}

@end

@implementation RSEditorView

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"RSEditor" owner:self];		
	}
	return self;
}

- (void)dealloc {
	[ibView release]; // root object
	[super dealloc];
}

- (NSView *)view {
	return ibView;
}

- (void)changeColor:(id)sender {
	WBTrace();
}

- (IBAction)changeStrokeWidth:(id)sender {
	rs_swidth = [sender floatValue];
	[NSApp sendAction:@selector(changeAttributes:) to:nil from:self];
}

- (IBAction)changeStrokeColor:(id)sender {
	[NSApp orderFrontColorPanel:sender]; // open color panel
	/* make first responder */
	[[ibView window] makeKeyWindow];
	[[ibView window] makeFirstResponder:ibView];
}

- (NSDictionary *)convertAttributes:(NSDictionary *)attributes {
	NSMutableDictionary *dict = nil;
	if (rs_swidth > 0) {
		NSNumber *current = WBCGFloat(-rs_swidth);
		NSNumber *previous = [attributes objectForKey:NSStrokeWidthAttributeName];
		if (!previous || ![previous isEqualToNumber:current]) {
			dict = [attributes mutableCopy];
			[dict setObject:current forKey:NSStrokeWidthAttributeName];
		}
	}	else if ([attributes objectForKey:NSStrokeWidthAttributeName]) {
		dict = [attributes mutableCopy];
		[dict removeObjectForKey:NSStrokeWidthAttributeName];
	}
	return dict ? [dict autorelease] : attributes;
}

- (void)updateAttributes:(NSTextView *)sender {
	NSDictionary *attrs;
	if ([sender isRichText]) {
		attrs = [sender typingAttributes];
	} else {
		NSTextStorage *storage = [sender textStorage];
		if ([storage length] > 0)
			attrs = [storage attributesAtIndex:0 effectiveRange:NULL];
		else
			attrs = [sender typingAttributes];
	}
	NSNumber *width = [attrs objectForKey:NSStrokeWidthAttributeName];
	if (width) {
		[ibWidth setFloatValue:-[width floatValue]];
	} else {
		[ibWidth setFloatValue:0];
	}
}

@end

@implementation RSTextView

static RSEditorView *sEditor = nil;

+ (void)initialize {
	if ([RSTextView class] == self) {
		sEditor = [[RSEditorView alloc] init];
		[[NSFontPanel sharedFontPanel] setAccessoryView:[sEditor view]];
	}
}

- (void)updateFontPanel {
	[super updateFontPanel];
	[sEditor updateAttributes:self];
}

@end

