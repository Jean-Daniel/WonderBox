/*
 *  WBDaemonTask.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import "WBDaemonTask.h"

#include <launch.h>
#include <servers/bootstrap.h>

#import "WBServiceManagement.h"

@interface WBDaemonTask ()
- (void)_cleanup:(BOOL)force;
- (void)_addMachService:(NSString *)portName properties:(id)properties;
@end

static NSMutableSet *sDaemons = nil;

static
void _WBDaemonCleanup(void) {
  NSArray *daemons = [sDaemons copy];
  for (WBDaemonTask *task in daemons)
    [task _cleanup:NO];
  wb_release(daemons);
}

static
void __WBDaemonUnregisterAtExit(WBDaemonTask *aDaemon) {
  @synchronized([WBDaemonTask class]) {
    if (!sDaemons) {
      sDaemons = [[NSMutableSet alloc] init];
      atexit(_WBDaemonCleanup);
    }
    [sDaemons addObject:aDaemon];
  }
}

@implementation WBDaemonTask

@synthesize delegate = wb_delegate;

- (id)initWithName:(NSString *)aName {
  if (self = [self init]) {
    self.name = aName;
    _unregister = YES; // by default, cleanup at exit
    CFDictionaryRef properties = WBServiceCopyJob(WBNSToCFString(aName), NULL);
    if (properties) {
      _registred = YES;
      _properties = [WBCFToNSDictionary(properties) mutableCopy];
      // remove volatile properties
      [_properties removeObjectForKey:@LAUNCH_JOBKEY_PID];
      [_properties removeObjectForKey:@"TransactionCount"];
      [_properties removeObjectForKey:@"PerJobMachServices"];
      // FIXME: should reset it instead
      [_properties removeObjectForKey:@LAUNCH_JOBKEY_MACHSERVICES];
      [_properties removeObjectForKey:@LAUNCH_JOBKEY_LASTEXITSTATUS];

      CFRelease(properties);
    }
  }
  return self;
}

- (void)dealloc {
  [self _cleanup:NO];
  wb_release(_properties);
  wb_dealloc();
}

// MARK: -
- (BOOL)isRegistred {
  return _registred;
}
- (BOOL)unregisterAtExit {
  return _unregister;
}
- (void)setUnregisterAtExit:(BOOL)flag {
  if (XOR(_unregister, flag)) {
    _unregister = flag;
    if (_registred) {
      if (_unregister) {
        __WBDaemonUnregisterAtExit(self);
      } else {
        [sDaemons removeObject:self];
      }
    }
  }
}

- (NSString *)name {
  return [self valueForProperty:@LAUNCH_JOBKEY_LABEL];
}
- (void)setName:(NSString *)aName {
  [self setValue:wb_autorelease([aName copy]) forProperty:@LAUNCH_JOBKEY_LABEL];
}

- (NSString *)launchPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_PROGRAM];
}
- (void)setLaunchPath:(NSString *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_PROGRAM];
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
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_KEEPALIVE];
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
  return [[self valueForProperty:@LAUNCH_JOBKEY_TIMEOUT] unsignedIntValue];
}
- (void)setTimeout:(uint32_t)aValue {
  [self setValue:[NSNumber numberWithUnsignedInteger:aValue] forProperty:@LAUNCH_JOBKEY_TIMEOUT];
}

- (uint32_t)exitTimeout {
  return [[self valueForProperty:@LAUNCH_JOBKEY_EXITTIMEOUT] unsignedIntValue];
}
- (void)setExitTimeout:(uint32_t)aValue {
  [self setValue:[NSNumber numberWithUnsignedInteger:aValue] forProperty:@LAUNCH_JOBKEY_EXITTIMEOUT];
}

- (uint32_t)throttleInterval {
  return [[self valueForProperty:@LAUNCH_JOBKEY_THROTTLEINTERVAL] unsignedIntValue];
}
- (void)setThrottleInterval:(uint32_t)aValue {
  [self setValue:[NSNumber numberWithUnsignedInteger:aValue] forProperty:@LAUNCH_JOBKEY_THROTTLEINTERVAL];
}

- (BOOL)startImmediatly {
  return [[self valueForProperty:@LAUNCH_JOBKEY_RUNATLOAD] boolValue];
}
- (void)setStartImmediatly:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_RUNATLOAD];
}

- (BOOL)launchOnlyOnce {
  return [[self valueForProperty:@LAUNCH_JOBKEY_LAUNCHONLYONCE] boolValue];
}
- (void)setLaunchOnlyOnce:(BOOL)flag {
  [self setValue:[NSNumber numberWithBool:flag] forProperty:@LAUNCH_JOBKEY_LAUNCHONLYONCE];
}

- (NSString *)standardError {
  return [self valueForProperty:@LAUNCH_JOBKEY_STANDARDERRORPATH];
}
- (void)setStandardError:(NSString *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_STANDARDERRORPATH];
}
- (NSString *)standardOutput {
  return [self valueForProperty:@LAUNCH_JOBKEY_STANDARDOUTPATH];
}
- (void)setStandardOutput:(NSString *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_STANDARDOUTPATH];
}

- (NSString *)rootDirectoryPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_ROOTDIRECTORY];
}
- (void)setRootDirectoryPath:(NSString *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_ROOTDIRECTORY];
}

- (NSString *)workingDirectoryPath {
  return [self valueForProperty:@LAUNCH_JOBKEY_WORKINGDIRECTORY];
}
- (void)setWorkingDirectoryPath:(NSString *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_WORKINGDIRECTORY];
}

- (NSArray *)arguments {
  return [self valueForProperty:@LAUNCH_JOBKEY_PROGRAMARGUMENTS];
}
- (void)setArguments:(NSArray *)aValue {
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_PROGRAMARGUMENTS];
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
  [self setValue:wb_autorelease([aValue copy]) forProperty:@LAUNCH_JOBKEY_ENVIRONMENTVARIABLES];
}

- (id)valueForProperty:(NSString *)aProperty {
  return [_properties objectForKey:aProperty];
}
- (void)setValue:(id)anObject forProperty:(NSString *)aProperty {
  if (_registred)
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
  WBDaemonTask *self = (__bridge WBDaemonTask *)info;
  NSString *service = nil;
  @synchronized(self) {
    if (self->_ports) {
      // Not very efficient but good enough for this task.
      for (NSString *key in WBCFToNSDictionary(self->_ports)) {
        CFMachPortRef value = (CFMachPortRef)CFDictionaryGetValue(self->_ports, (__bridge void *)key);
        if (value == port) {
          service = wb_retain(key);
          DLog(@"death of port %@", key);
          CFDictionaryRemoveValue(self->_ports, (__bridge void *)key);
          break;
        }
      }
    }
  }
  // Notify outside of the lock to avoid dead lock.
  if (service) {
    if (self->wb_delegate && [self->wb_delegate respondsToSelector:@selector(task:didTerminateService:)])
      [self->wb_delegate task:self didTerminateService:service];
    wb_release(service);
  }
}

- (mach_port_t)serviceForName:(NSString *)aName {
  CFMachPortRef cfport;
  @synchronized(self) {
    cfport = _ports ? (CFMachPortRef)CFDictionaryGetValue(_ports, (__bridge void *)aName) : NULL;
    if (cfport) {
      if (CFMachPortIsValid(cfport)) // cache hit
        return CFMachPortGetPort(cfport);
      // invalid port
      CFDictionaryRemoveValue(_ports, (__bridge void *)aName);
      cfport = NULL;
    }
  }

  mach_port_t port;
  kern_return_t kr = bootstrap_look_up(bootstrap_port, [aName UTF8String], &port);
  if (KERN_SUCCESS == kr) {
    // cache port and listen death notification
    CFMachPortContext ctxt = {
      .version = 0,
      .info = (__bridge void *)self,
      .retain = CFRetain,
      .release = CFRelease,
      .copyDescription = CFCopyDescription,
    };
    cfport = CFMachPortCreateWithPort(kCFAllocatorDefault, port, NULL, &ctxt, NULL);
    if (cfport) {
      @synchronized(self) {
        if (!_ports)
          _ports = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                             &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(_ports, (__bridge void *)aName, cfport);
      }
      CFMachPortSetInvalidationCallBack(cfport, _CFMachPortInvalidation);
      CFRelease(cfport);
    }
    return port;
  } else {
    WBLogWarning(@"bootstrap_look_up: %s", bootstrap_strerror(kr));
  }

  return MACH_PORT_NULL;
}

// MARK: -
- (void)_cleanup:(BOOL)force {
  @synchronized([WBDaemonTask class]) {
    [sDaemons removeObject:self];
  }
  if (_registred && (_unregister || force)) {
    CFErrorRef error;
    bool unregistred = WBServiceUnregisterJob(WBNSToCFString(self.name), &error);
    if (!unregistred) {
      if ((CFErrorGetDomain(error) == kCFErrorDomainPOSIX && CFErrorGetCode(error) == ESRCH) ||
          (CFErrorGetDomain(error) == kCFErrorDomainOSStatus && CFErrorGetCode(error) == kPOSIXErrorESRCH)) {
        // No such process mean the service is not registred:
        unregistred = true;
      } else {
        WBLogWarning(@"Error while unregistring daemon: %@, %@", self.name, (id)error);
      }
      CFRelease(error);
    }
    if (unregistred) {
      [self willChangeValueForKey:@"registred"];
      _registred = NO;
      [self didChangeValueForKey:@"registred"];
    }
  }

  @synchronized(self) {
    if (_ports) {
      for (NSString *key in WBCFToNSDictionary(_ports)) {
        CFMachPortRef port = (CFMachPortRef)CFDictionaryGetValue(_ports, (__bridge void *)key);
        CFMachPortSetInvalidationCallBack(port, NULL);
      }
      CFRelease(_ports);
      _ports = NULL;
    }
  }
}

- (BOOL)registerDaemon:(NSError **)outError {
  if (_registred)
    WBThrowException(NSInvalidArgumentException, @"already registred !");

  CFErrorRef error;
  if (!WBServiceRegisterJob(WBNSToCFDictionary(_properties), &error)) {
    if (outError)
      *outError = wb_autorelease(wb_retain(WBCFToNSError(error)));
    
    CFRelease(error);
    return NO;
  }

  [self willChangeValueForKey:@"registred"];
  _registred = YES;
  [self didChangeValueForKey:@"registred"];

  if (_unregister)
    __WBDaemonUnregisterAtExit(self);

  return YES;
}

//- (BOOL)unregisterDaemon:(NSError **)outError {
//  CFErrorRef error;
//  if (!WBServiceUnregisterJob((CFStringRef)self.name, &error)) {
//    if (outError)
//      *outError = [NSMakeCollectable(error) autorelease];
//    else
//      CFRelease(error);
//    return NO;
//  }
//  @synchronized([WBDaemonTask class]) {
//    [sDaemons removeObject:self];
//  }
//  [self willChangeValueForKey:@"registred"];
//  _registred = NO;
//  [self didChangeValueForKey:@"registred"];
//  return YES;
//}

- (void)unregister {
  [self _cleanup:YES];
}

@end
