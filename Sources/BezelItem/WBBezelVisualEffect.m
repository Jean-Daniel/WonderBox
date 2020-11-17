/*
 *  WBBezelVisualEffect.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2015 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBBezelVisualEffect.h"

#pragma mark -
@interface NSVisualEffectView (WBPrivate)
// This is the secret method to get the exact matching appearance of the system Bezel UI.
// No longer available in macOS 11.0
- (void)_setInternalMaterialType:(long long)arg1;
@end

@interface NSWindow (WBPrivate)
- (NSImage *)_cornerMask;
- (float)_backdropBleedAmount;
@end

static
NSImage *_bezelWindowMask() {
  NSImage *img = [NSImage imageWithSize:NSMakeSize(37, 37) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
    [[NSColor blackColor] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:dstRect] fill];
    return YES;
  }];
  img.capInsets = NSEdgeInsetsMake(18, 18, 18, 18);
  img.resizingMode = NSImageResizingModeTile;
  return img;
}

static inline bool _IsDarkTheme() {
  bool black = false;
  CFStringRef theme = CFPreferencesCopyAppValue(CFSTR("AppleInterfaceStyle"), kCFPreferencesAnyApplication);
  if (theme) {
    black = CFEqual(CFSTR("Dark"), theme);
    CFRelease(theme);
  }
  return black;
}

@protocol _WBBezelVisualEffectLevelView
@property(nonatomic) CGFloat levelValue;
@end

@interface _WBBezelDarkLevelBarLegacy : NSVisualEffectView <_WBBezelVisualEffectLevelView>
@property(nonatomic) CGFloat levelValue;
@end

@interface _WBBezelDarkLevelBar : NSView <_WBBezelVisualEffectLevelView>
@property(nonatomic) CGFloat levelValue;
@end

@interface _WBBezelLightLevelBar : NSView <_WBBezelVisualEffectLevelView>
@property(nonatomic) CGFloat levelValue;
@end

#pragma mark -
@implementation WBVisualEffectBezelWindow {
  NSImage *_corners;
  // Listen system theme change.
  id<NSObject> _themeObserver;
  NSView<_WBBezelVisualEffectLevelView> *_levelView;
}

+ (bool)available {
  // Only tested on 10.12 - 10.15
  NSOperatingSystemVersion vers = [NSProcessInfo processInfo].operatingSystemVersion;
  return (vers.majorVersion == 10 && vers.minorVersion <= 15) || vers.majorVersion == 11;
}

- (instancetype)initWithImageView:(NSImageView *)aView {
  if (self = [super initWithImageView:aView]) {
    NSVisualEffectView *v = [[NSVisualEffectView alloc] initWithFrame:((NSView *)self.contentView).frame];
    v.state = NSVisualEffectStateActive;
    v.maskImage = _bezelWindowMask();
    self.contentView = v;
    [v addSubview:aView];

    // Notification send when modifying "dark menubar" setting in System Preferences.
    __unsafe_unretained WBVisualEffectBezelWindow *window = self;
    self->_themeObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"AppleInterfaceThemeChangedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
      // update window theme.
      [window setDarkTheme:_IsDarkTheme()];
    }];

    [self setDarkTheme:_IsDarkTheme()];

    _corners = _bezelWindowMask();
    // NSWindow requires stretching mode
    _corners.resizingMode = NSImageResizingModeStretch;
  }
  return self;
}

- (void)dealloc {
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:_themeObserver];
}

// MARK: -
- (NSImage *)_cornerMask {
  return _corners;
}

// I don't have any idea what it is about, but this is how BezelUI Server works.
- (float)_backdropBleedAmount { return 0; }

- (CGFloat)levelValue { return _levelView.levelValue; }
- (void)setLevelValue:(CGFloat)levelValue { _levelView.levelValue = levelValue; }

- (BOOL)isLevelBarVisible {
  return [_levelView superview] != nil;
}

- (void)setLevelBarVisible:(BOOL)levelBarVisible {
  if (levelBarVisible && ![_levelView superview]) {
    [self.contentView addSubview:_levelView];
  } else if (!levelBarVisible && [_levelView superview]) {
    [_levelView removeFromSuperview];
  }
}

- (void)setDarkTheme:(BOOL)isDark {
  NSVisualEffectView *v = self.contentView;
  // From BezelUIServer reverse engineering
  if (isDark) {
    // When Dark MenuBar mode is enabled, we have to use dark material.
    v.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    if ([v respondsToSelector:@selector(_setInternalMaterialType:)]) {
      v.material = NSVisualEffectMaterialDark;
      [v _setInternalMaterialType:4];
    } else if (@available(macOS 11.0, *)) {
      v.material = 26; // Bezel Window (private material)
    }
  } else {
    v.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    if ([v respondsToSelector:@selector(_setInternalMaterialType:)]) {
      v.material = NSVisualEffectMaterialLight;
      [v _setInternalMaterialType:0];
    } else if (@available(macOS 11.0, *)) {
      v.material = 26; // Bezel Window
    }
  }
  [self updateLevelViewTheme:isDark];
}

- (void)updateLevelViewTheme:(BOOL)isDark {
  bool shows = [_levelView superview] != nil;
  CGFloat level = _levelView.levelValue;

  if (shows)
    [_levelView removeFromSuperview];

  Class cls;
  if (isDark) {
    if (@available(macOS 11.0, *))
      cls = [_WBBezelDarkLevelBar class];
    else
      cls = [_WBBezelDarkLevelBarLegacy class];
  } else {
    cls = [_WBBezelLightLevelBar class];
  }
  _levelView = [[cls alloc] initWithFrame:CGRectMake(20, 20, 161, 8)];
  _levelView.levelValue = level;
  if (shows)
    [self.contentView addSubview:_levelView];
}

@end


// MARK: -
@interface _WBBezelLightLevelBlock : NSVisualEffectView
- (BOOL)allowsVibrancy;
@end

@interface _WBBezelDarkLevelBlock : NSView
- (BOOL)allowsVibrancy;
@end

@interface _WBBezelLevelBlocks : NSObject
- (instancetype)initWithView:(NSView *)v blockClass:(Class)cls;
- (void)setLevelValue:(CGFloat)value;
@end

@implementation _WBBezelLightLevelBar {
  _WBBezelLevelBlocks *_blocks;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    _blocks = [[_WBBezelLevelBlocks alloc] initWithView:self blockClass:[_WBBezelLightLevelBlock class]];
  }
  return self;
}

- (void)setLevelValue:(CGFloat)levelValue {
  if (fnotequal(_levelValue, levelValue)) {
    _levelValue = MIN(1., MAX(0., levelValue));
    [_blocks setLevelValue:_levelValue];
  }
}

- (void)viewDidMoveToWindow {
  [_blocks setLevelValue:_levelValue];
}

- (void)drawRect:(NSRect)rect {
  [[NSColor secondaryLabelColor] set];
  NSRectFillUsingOperation(self.bounds, [NSGraphicsContext.currentContext compositingOperation]);
}

@end

@implementation _WBBezelDarkLevelBarLegacy {
  _WBBezelLevelBlocks *_blocks;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.material = NSVisualEffectMaterialDark;
    self.state = NSVisualEffectStateActive;

    _blocks = [[_WBBezelLevelBlocks alloc] initWithView:self blockClass:[_WBBezelDarkLevelBlock class]];
  }
  return self;
}

- (void)setLevelValue:(CGFloat)levelValue {
  if (fnotequal(_levelValue, levelValue)) {
    _levelValue = MIN(1., MAX(0., levelValue));
    [_blocks setLevelValue:_levelValue];
  }
}

- (void)viewDidMoveToWindow {
  [_blocks setLevelValue:_levelValue];
  [super viewDidMoveToWindow];
}

- (void)drawRect:(NSRect)rect {
  [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:.25] set];
  NSRectFillUsingOperation(self.bounds, [NSGraphicsContext.currentContext compositingOperation]);
}

@end

@implementation _WBBezelDarkLevelBar {
  _WBBezelLevelBlocks *_blocks;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    _blocks = [[_WBBezelLevelBlocks alloc] initWithView:self blockClass:[_WBBezelDarkLevelBlock class]];
  }
  return self;
}

- (void)setLevelValue:(CGFloat)levelValue {
  if (fnotequal(_levelValue, levelValue)) {
    _levelValue = MIN(1., MAX(0., levelValue));
    [_blocks setLevelValue:_levelValue];
  }
}

- (void)viewDidMoveToWindow {
  [_blocks setLevelValue:_levelValue];
  [super viewDidMoveToWindow];
}

- (BOOL)allowsVibrancy {
  return NO;
}

- (void)drawRect:(NSRect)rect {
  [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:.25] set];
  NSRectFillUsingOperation(self.bounds, [NSGraphicsContext.currentContext compositingOperation]);
}

@end

@implementation _WBBezelLevelBlocks {
  NSView *_view;
  Class _blockClass;
  NSUInteger _bidx;
  NSMutableArray *_blocks;
}

- (instancetype)initWithView:(NSView *)v blockClass:(Class)cls {
  if (self = [super init]) {
    _view = v;
    _blockClass = cls;
    _blocks = [[NSMutableArray alloc] init];
  }
  return self;
}

- (NSView *)blockWithFrame:(CGRect)frame {
  NSView *block;
  if (_bidx >= _blocks.count) {
    block = [[_blockClass alloc] initWithFrame:frame];
    _blocks[_bidx] = block;
  } else {
    block = _blocks[_bidx];
    block.frame = frame;
  }
  ++_bidx;
  return block;
}

- (void)setLevelValue:(CGFloat)value {
  if (_view.window) {
    [_blocks makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _bidx = 0;

    double one = 0.0625;
    int blocks = (int)(value / one);
    CGRect block = CGRectMake(1, 1, 9, 6);
    for (int idx = 0; idx < blocks; ++idx) {
      // Draw complete block
      [_view addSubview:[self blockWithFrame:block]];
      block.origin.x += 10;
    }
    CGFloat fract;
    fract = modf(value / one, &fract);
    if (fract > 0.01) {
      block.size.width = fract * 9;
      block = [_view backingAlignedRect:block options:
               NSAlignWidthNearest | NSAlignMaxXNearest | NSAlignHeightNearest | NSAlignMaxYNearest];
      if (block.size.width > 0)
        [_view addSubview:[self blockWithFrame:block]];
    }
  }
}

@end

// MARK: -
// MARK: Light
@implementation _WBBezelLightLevelBlock

- (BOOL)allowsVibrancy {
  return NO;
}

- (void)drawRect:(NSRect)rect {
  [[NSColor whiteColor] set];
  NSRectFillUsingOperation(self.bounds, [NSGraphicsContext.currentContext compositingOperation]);
}

@end

// MARK: Dark
@implementation _WBBezelDarkLevelBlock

- (BOOL)allowsVibrancy {
  return YES;
}

- (void)drawRect:(NSRect)rect {
  [[NSColor secondaryLabelColor] set];
  NSRectFillUsingOperation(self.bounds, [NSGraphicsContext.currentContext compositingOperation]);
}

@end
