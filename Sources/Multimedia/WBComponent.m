/*
 *  WBComponent.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBComponent.h)

@implementation WBComponent

+ (NSArray *)componentsWithComponentDescription:(const ComponentDescription *)desc {
  if (!desc) return nil;
  
  ComponentDescription search = *desc;
  NSMutableArray *cmps = [NSMutableArray array];
  Component comp = FindNextComponent(NULL, &search);
  while (comp) {
    WBComponent *skcmp = [[self alloc] initWithComponent:comp];
    if (skcmp) {
      [cmps addObject:skcmp];
      [skcmp release];
    }
    comp = FindNextComponent(comp, &search);
  }
  return cmps;
}

+ (NSArray *)componentsWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu {
  ComponentDescription search = { type, subtype, manu, 0, 0 };
  return [self componentsWithComponentDescription:&search];
}

#pragma mark Convenient constructors
+ (id)componentWithType:(OSType)type subtype:(OSType)subtype manufacturer:(OSType)manu {
  return [[[self alloc] initWithType:type subtype:subtype manufactor:manu] autorelease];
}

+ (id)componentWithComponentDescription:(const ComponentDescription *)desc {
  return [self componentWithComponentDescription:desc next:NULL];
}

+ (id)componentWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component {
  return [[[self alloc] initWithComponentDescription:desc next:component] autorelease];
}

#pragma mark Protocols
- (id)copyWithZone:(NSZone *)aZone {
  WBComponent *copy = NSAllocateObject([self class], 0, aZone);
  
  copy->_comp =_comp;
  copy->_desc =_desc;
  
  copy->_icon = [_icon retain];
  copy->_name = [_name retain];
  copy->_manu = [_manu retain];
  copy->_info = [_info retain];
  copy->_cname = [_cname retain];
  
  return copy;
}

#pragma mark Initializer
- (id)initWithComponent:(const Component)comp {
  if (self = [super init]) {
    if (!comp || noErr != GetComponentInfo(comp, &_desc, NULL, NULL, NULL)) {
      [self release];
      return nil;
    }
    _comp = comp;
  }
  return self;
}

- (id)initWithComponentInstance:(const ComponentInstance)instance {
  return [self initWithComponent:(const Component)instance];
}

/* Using description */
- (id)initWithComponentDescription:(const ComponentDescription *)desc {
  return [self initWithComponentDescription:desc next:nil];
}

- (id)initWithType:(OSType)aType subtype:(OSType)aSubtype manufactor:(OSType)aManufactor {
  ComponentDescription desc = { aType, aSubtype, aManufactor, 0, 0};
  return [self initWithComponentDescription:&desc next:nil];
}

- (id)initWithComponentDescription:(const ComponentDescription *)desc next:(WBComponent *)component {
  Component comp = FindNextComponent(component ? component->_comp : NULL, (ComponentDescription *)desc);
  if (comp)
    return [self initWithComponent:comp];
  [self release];
  return nil;
}

- (void)dealloc {
  [_cname release];
  [_icon release];
  [_name release];
  [_manu release];
  [_info release];
  [super dealloc];
}

- (NSString *)description {
  OSType type = OSSwapHostToBigInt32(_desc.componentType);
  OSType subtype = OSSwapHostToBigInt32(_desc.componentSubType);
  return [NSString stringWithFormat:@"<%@ %p> { name: %@ ('%4.4s'/'%4.4s'), manufacturer: %@, info: %@ }", 
          [self class], self,
          [self name], &type, &subtype,
          [self manufacturer], [self informations]
          ];
}

#pragma mark -
- (void)wb_setInfo {
  if (!_name) {
    Handle h1 = NewHandle(4);
    Handle h2 = NewHandle(4);
    
		ComponentDescription desc;
		OSStatus err = GetComponentInfo(_comp, &desc, h1, h2, 0);
    
    if (noErr == err) {
      char* ptr1 = *h1;
      // Get the manufacturer's name... look for the ':' character convention
      _cname = [[NSString alloc] initWithBytes:*h1 + 1 length:**h1 encoding:NSMacOSRomanStringEncoding]; // pascal string
      
      size_t len = *ptr1++;
      char* displayStr = 0;
      
      for (size_t i = 0; i < len; ++i) {
        if (ptr1[i] == ':') { // found the name
          ptr1[i] = 0;
          displayStr = ptr1;
          break;
        }
      }
      
      if (displayStr) {
        _manu = [[NSString alloc] initWithCString:displayStr encoding:kCFStringEncodingMacRoman];
        
        // move displayStr ptr past the manu, to the name
        // we move the characters down a index, because the handle doesn't have any room
        // at the end for the \0
        size_t i = strlen(displayStr), j = 0;
        while (displayStr[++i] == ' ' && i < len)
          ;
        while (i < len)
          displayStr[j++] = displayStr[i++];
        displayStr[j] = 0;
        
        _name = [[NSString alloc] initWithCString:displayStr encoding:NSMacOSRomanStringEncoding];
      } else {
        switch (_desc.componentManufacturer) {
          default:
            _manu = [NSFileTypeForHFSTypeCode(_desc.componentManufacturer) retain];
            break;
          case 'appl':
            _manu = @"Apple";
            break;            
        }
        
        _name = [[NSString alloc] initWithBytes:ptr1 length:len encoding:NSMacOSRomanStringEncoding];
      }
      
      if (**h2 > 0) 
        _info = [[NSString alloc] initWithBytes:*h2 + 1 length:**h2 encoding:NSMacOSRomanStringEncoding];
    }
    DisposeHandle(h2);
		DisposeHandle(h1);
  }
}

- (NSImage *)icon {
  /* weak linking on NSImage */
  if (!_icon && NSClassFromString(@"NSImage")) {
    Handle h1 = NewHandle(4);
    OSStatus err = GetComponentInfo(_comp, NULL, NULL, NULL, h1);
    if (noErr == err) {
      // TODO: generate image
//      void *data = *h1;
//      size_t length = GetHandleSize(h1);
//      if (length > 0) {
//        NSData *bytes = [[NSData alloc] initWithBytesNoCopy:data length:length freeWhenDone:NO];
//        _icon = [[NSClassFromString(@"NSImage") alloc] initWithData:bytes];
//        [bytes release];
//      }
    }
    DisposeHandle(h1);
  }
  return _icon;
}

- (NSString *)name {
  if (!_cname)
    [self wb_setInfo];
  return [_name length] > 0 ? _name : _cname;
}
- (NSString *)manufacturer {
  if (!_cname)
    [self wb_setInfo];
  return _manu;
}
- (NSString *)informations {
  if (!_cname)
    [self wb_setInfo];
  return _info;
}
- (NSString *)componentName {
  if (!_cname)
    [self wb_setInfo];
  return _cname;
}

- (void)getComponentDescription:(ComponentDescription *)description {
  *description = _desc;
}

- (OSStatus)open:(ComponentInstance *)instance {
  return OpenAComponent(_comp, instance);
}

- (Component)component {
  return _comp;
}

- (UInt32)resourceVersion:(OSStatus *)error {
  bool versionFound = false;
  ResFileRefNum curRes = CurResFile();
	ResFileRefNum componentResFileID = kResFileNotOpened;
	
	OSStatus result;
  UInt32 version = 0;
	short thngResourceCount;
	
	require_noerr (result = OpenAComponentResFile(_comp, &componentResFileID), home);
	require_noerr (result = componentResFileID <= 0, home);
	
	UseResFile(componentResFileID);
  
	thngResourceCount = Count1Resources(kComponentResourceType);
	
	require_noerr (result = ResError(), home);
  // only go on if we successfully found at least 1 thng resource
	require_noerr (thngResourceCount <= 0 ? -1 : 0, home);
  
	// loop through all of the Component thng resources trying to 
	// find one that matches this Component description
	for (short i = 0; i < thngResourceCount && (!versionFound); i++)
	{
		// try to get a handle to this code resource
		Handle thngResourceHandle = Get1IndResource(kComponentResourceType, i+1);
		if (thngResourceHandle != NULL && ((*thngResourceHandle) != NULL))
		{
			if ((UInt32)GetHandleSize(thngResourceHandle) >= sizeof(ExtComponentResource))
			{
				ExtComponentResource * componentThng = (ExtComponentResource*) (*thngResourceHandle);
        
				// check to see if this is the thng resource for the particular Component that we are looking at
				// (there often is more than one Component described in the resource)
				if ((componentThng->cd.componentType == _desc.componentType) 
						&& (componentThng->cd.componentSubType == _desc.componentSubType) 
						&& (componentThng->cd.componentManufacturer == _desc.componentManufacturer))
				{
					version = componentThng->componentVersion;
					versionFound = true;
				}
			}
			ReleaseResource(thngResourceHandle);
		}
	}

	if (!versionFound)
		result = resNotFound;
  
	UseResFile(curRes);	// revert
	
	if ( componentResFileID != kResFileNotOpened )
		CloseComponentResFile(componentResFileID);
  
home:
  if (error) *error = result;
  if (result == noErr) return version;
  return 0;
}

@end

