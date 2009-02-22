/*
 *  WBComponent.h
 *  WonderBox
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

@interface WBComponent : NSObject <NSCopying> {
@private
  Component _comp;
	ComponentDescription _desc;
	
  NSImage *_icon;
	NSString *_manu, *_name, *_info, *_cname;
}

#if OBJC_NEW_PROPERTIES
@property(readonly) NSString *name;
@property(readonly) NSString *manufacturer;
@property(readonly) NSString *informations;
@property(readonly) NSString *componentName;

// TODO: find a component with icon to test it.
//@property(readonly) NSImage *icon;
#endif

+ (NSArray *)componentsWithComponentDescription:(const ComponentDescription *)search;
+ (NSArray *)componentsWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu;

+ (id)componentWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu;
+ (id)componentWithComponentDescription:(const ComponentDescription *)desc;
+ (id)componentWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component;

- (id)initWithComponent:(const Component)comp; // designated
- (id)initWithComponentInstance:(const ComponentInstance)instance;

- (id)initWithComponentDescription:(const ComponentDescription *)desc;
- (id)initWithType:(OSType)aType subtype:(OSType)aSubtype manufactor:(OSType)aManufactor;
- (id)initWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component;

- (NSString *)name;
- (NSString *)manufacturer;
- (NSString *)informations;
- (NSString *)componentName;

- (OSStatus)open:(ComponentInstance *)instance;

- (Component)component;
- (UInt32)resourceVersion:(OSStatus *)error;
- (void)getComponentDescription:(ComponentDescription *)description;

@end
