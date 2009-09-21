//
//  WBDaemonTask.m
//  dæmon
//
//  Created by Jean-Daniel Dupas on 18/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import "WBDaemonTask.h"

#include <launch.h>
#include <servers/bootstrap.h>

#import "WBServiceManagement.h"

@interface WBDaemonTask ()
- (void)_cleanup:(NSNotification *)aNotification;
- (void)_addMachService:(NSString *)portName properties:(id)properties;
@end

@implementation WBDaemonTask

- (id)initWithName:(NSString *)aName {
  if (self = [self init]) {
    self.name = aName;
  }
  return self;
}

- (void)dealloc {
  [self _cleanup:nil];
  [_properties release];
  [super dealloc];
}

// MARK: -
- (NSString *)name {
  return [self valueForProperty:@LAUNCH_JOBKEY_LABEL];
}
- (void)setName:(NSString *)aName {
  [self setValue:[[aName copy] autorelease] forProperty:@LAUNCH_JOBKEY_LABEL];
}

- (NSString *)launchPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_PROGRAM];
}
- (void)setLaunchPath:(NSString *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_PROGRAM];
}

- (BOOL)isDisabled {
  return [[self valueForProperty:@LAUNCH_JOBKEY_DISABLED] boolValue];
} 
- (void)setDisabled:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_DISABLED];
}

- (NSObject<NSCopying> *)keepAlive {
  return [self valueForProperty:@LAUNCH_JOBKEY_KEEPALIVE];
}
- (void)setKeepAlive:(NSObject<NSCopying> *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_KEEPALIVE];
}

- (BOOL)debug {
  return [[self valueForProperty:@LAUNCH_JOBKEY_DEBUG] boolValue];
} 
- (void)setDebug:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_DEBUG];
}

- (BOOL)waitForDebugger {
  return [[self valueForProperty:@LAUNCH_JOBKEY_WAITFORDEBUGGER] boolValue];
} 
- (void)setWaitForDebugger:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_WAITFORDEBUGGER];
}

//@property(retain) id keepAlive;
- (uint32_t)timeout {
  return [[self valueForProperty:@LAUNCH_JOBKEY_TIMEOUT] unsignedIntegerValue];
} 
- (void)setTimeout:(uint32_t)aValue {
  [self setValue:[NSNumber numberWithUnsignedInteger:aValue] forProperty:@LAUNCH_JOBKEY_TIMEOUT];
}

- (uint32_t)exitTimeout {
  return [[self valueForProperty:@LAUNCH_JOBKEY_EXITTIMEOUT] unsignedIntegerValue];
} 
- (void)setExitTimeout:(uint32_t)aValue {
  [self setValue:[NSNumber numberWithUnsignedInteger:aValue] forProperty:@LAUNCH_JOBKEY_EXITTIMEOUT];
}

- (BOOL)startImmediatly {
  return [[self valueForProperty:@LAUNCH_JOBKEY_RUNATLOAD] boolValue];
} 
- (void)setStartImmediatly:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_RUNATLOAD];
}

- (BOOL)unregisterAtExit {
  return [[self valueForProperty:@LAUNCH_JOBKEY_LAUNCHONLYONCE] boolValue];
} 
- (void)setUnregisterAtExit:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_LAUNCHONLYONCE];
}

- (NSString *)standardError {
  return [self valueForProperty:@LAUNCH_JOBKEY_STANDARDERRORPATH];
}
- (void)setStandardError:(NSString *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_STANDARDERRORPATH];
}
- (NSString *)standardOutput {
  return [self valueForProperty:@LAUNCH_JOBKEY_STANDARDOUTPATH];
}
- (void)setStandardOutput:(NSString *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_STANDARDOUTPATH];
}

- (NSString *)rootDirectoryPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_ROOTDIRECTORY];
}
- (void)setRootDirectoryPath:(NSString *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_ROOTDIRECTORY];
}

- (NSString *)workingDirectoryPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_WORKINGDIRECTORY];
}
- (void)setWorkingDirectoryPath:(NSString *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_WORKINGDIRECTORY];
}

- (NSArray *)arguments {
  return [self valueForProperty:@LAUNCH_JOBKEY_PROGRAMARGUMENTS];
}
- (void)setArguments:(NSArray *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_PROGRAMARGUMENTS];
}
- (BOOL)globArguments {
  return [[self valueForProperty:@LAUNCH_JOBKEY_ENABLEGLOBBING] boolValue];
}
- (void)setGlobArguments:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_ENABLEGLOBBING];
}

- (NSDictionary *)environment {
  return [self valueForProperty:@LAUNCH_JOBKEY_ENVIRONMENTVARIABLES];
}
- (void)setEnvironment:(NSDictionary *)aValue {
  [self setValue:[[aValue copy] autorelease] forProperty:@LAUNCH_JOBKEY_ENVIRONMENTVARIABLES];
}

- (id)valueForProperty:(NSString *)aProperty {
  return [_properties objectForKey:aProperty];
}
- (void)setValue:(id)anObject forProperty:(NSString *)aProperty {
  if (_running) 
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"running !" userInfo:nil];
  
  if (!_properties) _properties = [[NSMutableDictionary alloc] init];
  if (anObject)
    [_properties setValue:anObject forKey:aProperty];
  else
    [_properties removeObjectForKey:aProperty];
}

// MARK: Mach Services
- (void)addMachService:(NSString *)portName {
  [self _addMachService:portName properties:[NSNumber numberWithBool:YES]];  
}
- (void)addMachService:(NSString *)portName properties:(NSDictionary *)properties {
  [self _addMachService:portName properties:properties];
}

- (void)_addMachService:(NSString *)portName properties:(id)properties {
  NSParameterAssert(properties);
  NSMutableDictionary *services = [self valueForProperty:@LAUNCH_JOBKEY_MACHSERVICES];
  if (!services) {
    services = [NSMutableDictionary dictionary];
    [self setValue:services forProperty:@LAUNCH_JOBKEY_MACHSERVICES];
  }
  [services setObject:properties forKey:portName];
}

static
void _CFMachPortInvalidation(CFMachPortRef port, void *info) {
  WBDaemonTask *self = (WBDaemonTask *)info;
  if (self->_ports) {
    for (NSString *key in (NSDictionary *)self->_ports) {
      CFMachPortRef value = (CFMachPortRef)CFDictionaryGetValue(self->_ports, key);
      if (value == port) {
        NSLog(@"death of port %@", key);
        CFDictionaryRemoveValue(self->_ports, key);
        break;
      }
    }
  }
}

- (mach_port_t)serviceForName:(NSString *)aName {
  CFMachPortRef cfport = _ports ? (CFMachPortRef)CFDictionaryGetValue(_ports, aName) : NULL;
  if (cfport) {
    if (CFMachPortIsValid(cfport)) // cache hit
      return CFMachPortGetPort(cfport);
    // invalid port
    CFDictionaryRemoveValue(_ports, aName);
    cfport = NULL;
  }
  
  mach_port_t port;
  kern_return_t kr = bootstrap_look_up(bootstrap_port, [aName UTF8String], &port);
  if (KERN_SUCCESS == kr) {
    // cache port and listen death notification
    CFMachPortContext ctxt = {
      .version = 0,
      .info = self,
      .retain = CFRetain,
      .release = CFRelease,
      .copyDescription = CFCopyDescription,
    };
    cfport = CFMachPortCreateWithPort(kCFAllocatorDefault, port, NULL, &ctxt, NULL);
    if (cfport) {
      if (!_ports) _ports = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
                                                      &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
      CFDictionarySetValue(_ports, aName, cfport);
      CFMachPortSetInvalidationCallBack(cfport, _CFMachPortInvalidation);
    }
    return port;
  } else {
    WBLogWarning(@"bootstrap_look_up: %s", bootstrap_strerror(kr));
  }

  return MACH_PORT_NULL;
}

// MARK: -
- (void)_cleanup:(NSNotification *)aNotification {
  CFErrorRef error;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  if (_running && !WBServiceUnregisterJob((CFStringRef)self.name, &error)) {
    CFShow(error);
    CFRelease(error);
  } else {
    _running = NO;   
  }
  if (_ports) {
    for (NSString *key in (NSDictionary *)_ports) {
      CFMachPortRef port = (CFMachPortRef)CFDictionaryGetValue(_ports, key);
      CFMachPortSetInvalidationCallBack(port, NULL);
    }
    CFRelease(_ports);
    _ports = NULL;  
  }
}

- (BOOL)launch:(NSError **)outError {
  if (_running) 
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"running !" userInfo:nil];
  
  CFErrorRef error;
  if (!WBServiceRegisterJob((CFDictionaryRef)_properties, &error)) {
    bool ok = false;
//    if (CFErrorGetCode(error) == kPOSIXErrorEEXIST && WBServiceUnregisterJob((CFStringRef)self.name, NULL)) {
//      CFRelease(error);
//      // second chance: need wait before register, else it conflict
//      ok = WBServiceRegisterJob((CFDictionaryRef)_properties, &error);
//    }
    
    if (!ok) {
      if (outError)
        *outError = [NSMakeCollectable(error) autorelease];
      else
        CFRelease(error);
      return NO;
    }
  }
  _running = YES;
  // listen for application death notification
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(_cleanup:) name:NSApplicationWillTerminateNotification 
                                             object:nil];
  // TODO: listen for application crash too.
  
  
  return YES;
}

- (void)terminate {
  [self _cleanup:nil];
}

@end
