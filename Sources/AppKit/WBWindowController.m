/*
 *  WBWindowController.m
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBWindowController.h)

WB_INLINE
void __WBWindowRegisterNotification(id self, NSWindow *aWindow) {
  if (aWindow) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wb_windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:aWindow];
  }
}

@implementation WBWindowController

+ (NSString *)nibName {
  return NSStringFromClass(self);
}

+ (NSString *)frameAutoSaveName {
  return NSStringFromClass(self);
}

- (id)initWithWindow:(NSWindow *)window {
  if (self = [super initWithWindow:window]) {
    NSString *saveName = [[self class] frameAutoSaveName];
    if (saveName)
      [self setWindowFrameAutosaveName:saveName];
    wb_modalStatus = NSRunStoppedResponse;
    __WBWindowRegisterNotification(self, window);
  }
  return self;
}

- (id)init {
  return [self initWithWindowNibName:[[self class] nibName]];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSWindowWillCloseNotification
                                                object:nil];
  [super dealloc];
}

#pragma mark -
- (void)windowDidLoad {
  [super windowDidLoad];
  __WBWindowRegisterNotification(self, [self window]);
}

#pragma mark -
- (IBAction)close:(id)sender {
  if ([[self window] isSheet]) {
    [NSApp endSheet:[self window] returnCode:wb_modalStatus];
  } else if ([NSApp modalWindow] == [self window]) {
    [NSApp stopModalWithCode:wb_modalStatus];
  }
  [self close];
}

- (BOOL)isReleasedWhenClosed {
  return wb_wcFlags.autorelease;
}

- (void)setReleasedWhenClosed:(BOOL)release {
  WBFlagSet(wb_wcFlags.autorelease, release);
}

- (NSInteger)runModal:(BOOL)processRunLoop {
  NSInteger result = 0;
  if (processRunLoop) {
    /* Create a modal session, and in each loop, 
    we process the default runloop event sources (url download, network connections, etc.) */
    NSModalSession session = [NSApp beginModalSessionForWindow:[self window]];
    for (;;) {
      if ((result = [NSApp runModalSession:session]) != NSRunContinuesResponse)
        break;
      /* Note: Do not use a 0 timeout, else this loop will never block and will consume a lots of CPU.
       In fact, UI events trigger the runloop, so we can use a big timeout value. */
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 120, true);
    }
    [NSApp endModalSession:session];
  } else {
    result = [NSApp runModalForWindow:[self window]];
  }
  return result;
}
- (NSInteger)modalResultCode {
  return wb_modalStatus;
}
- (void)setModalResultCode:(NSInteger)code {
  wb_modalStatus = code;
}

#pragma mark -
#pragma mark Window notification
- (void)windowWillClose {
  // to be overrided
}

- (void)wb_windowWillClose:(NSNotification *)aNotification {
  /* Check for safety. The window may be closed without a call to close: */
  if ([NSApp modalWindow] == [self window]) {
    [NSApp stopModalWithCode:wb_modalStatus];
  }
  /* notify after setting modal status */
  [self windowWillClose];
  if ([self isReleasedWhenClosed]) {
    [self autorelease];
  }
}

@end
