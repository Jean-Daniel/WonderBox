/*
 *  WBDaemonTask.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBBase.h)

@protocol WBDaemonTaskDelegate;
WB_OBJC_EXPORT
@interface WBDaemonTask : NSObject {
@private
  BOOL _registred;
  BOOL _unregister;
  CFMutableDictionaryRef _ports;
  NSMutableDictionary *_properties;
  id<WBDaemonTaskDelegate> wb_delegate __weak;
}

@property BOOL unregisterAtExit;
@property(assign) id<WBDaemonTaskDelegate> delegate;
@property(getter=isRegistred, readonly) BOOL registred;

- (id)initWithName:(NSString *)aName;

@property(copy) NSString *name;
@property(getter=isDisabled) BOOL disabled;

@property BOOL debug;
@property BOOL waitForDebugger;

@property(copy) NSObject<NSCopying> *keepAlive;

@property uint32_t timeout; // seconds
@property uint32_t exitTimeout; // seconds
@property uint32_t throttleInterval; // seconds

@property BOOL launchOnlyOnce; // run once
@property BOOL startImmediatly; // run at load

@property(copy) NSString *standardError;
@property(copy) NSString *standardOutput;

@property(copy) NSString *rootDirectoryPath;
@property(copy) NSString *workingDirectoryPath;

@property(copy) NSDictionary *environment;

@property BOOL globArguments;
@property(copy) NSArray *arguments;
@property(copy) NSString *launchPath; // program

- (id)valueForProperty:(NSString *)aProperty;
- (void)setValue:(id)anObject forProperty:(NSString *)aProperty;

// MARK: Running
- (BOOL)registerDaemon:(NSError **)outError;
- (void)unregister;

- (void)addMachService:(NSString *)portName;
- (void)addMachService:(NSString *)portName properties:(NSDictionary *)properties;
//#define LAUNCH_JOBKEY_MACH_RESETATCLOSE          "ResetAtClose"
//#define LAUNCH_JOBKEY_MACH_HIDEUNTILCHECKIN      "HideUntilCheckIn"
//#define LAUNCH_JOBKEY_MACH_DRAINMESSAGESONCRASH  "DrainMessagesOnCrash"
- (mach_port_t)serviceForName:(NSString *)aName;

// TODO: Socket support
//- (void)addSocket:(id)aKey properties:(NSDictionary *)properties;
//- (int)socketForKey:(id)aKey;

@end

@protocol WBDaemonTaskDelegate <NSObject>
@optional
- (void)task:(WBDaemonTask *)aTask didTerminateService:(NSString *)aService;
@end


//#define LAUNCH_JOBKEY_MACHSERVICELOOKUPPOLICIES     "MachServiceLookupPolicies"
//#define LAUNCH_JOBKEY_LIMITLOADTOHOSTS              "LimitLoadToHosts"
//#define LAUNCH_JOBKEY_LIMITLOADFROMHOSTS            "LimitLoadFromHosts"
//#define LAUNCH_JOBKEY_LIMITLOADTOSESSIONTYPE        "LimitLoadToSessionType"
//#define LAUNCH_JOBKEY_UMASK                         "Umask"
//#define LAUNCH_JOBKEY_NICE                          "Nice"
//#define LAUNCH_JOBKEY_LOWPRIORITYIO                 "LowPriorityIO"
//#define LAUNCH_JOBKEY_SESSIONCREATE                 "SessionCreate"
//#define LAUNCH_JOBKEY_STARTONMOUNT                  "StartOnMount"
//#define LAUNCH_JOBKEY_SOFTRESOURCELIMITS            "SoftResourceLimits"
//#define LAUNCH_JOBKEY_HARDRESOURCELIMITS            "HardResourceLimits"
//#define LAUNCH_JOBKEY_STANDARDINPATH                "StandardInPath"
//#define LAUNCH_JOBKEY_QUEUEDIRECTORIES              "QueueDirectories"
//#define LAUNCH_JOBKEY_WATCHPATHS                    "WatchPaths"
//#define LAUNCH_JOBKEY_STARTINTERVAL                 "StartInterval"
//#define LAUNCH_JOBKEY_STARTCALENDARINTERVAL         "StartCalendarInterval"
//#define LAUNCH_JOBKEY_BONJOURFDS                    "BonjourFDs"
//#define LAUNCH_JOBKEY_LASTEXITSTATUS                "LastExitStatus"
//#define LAUNCH_JOBKEY_PID                           "PID"
//#define LAUNCH_JOBKEY_ABANDONPROCESSGROUP           "AbandonProcessGroup"
//#define LAUNCH_JOBKEY_IGNOREPROCESSGROUPATSHUTDOWN  "IgnoreProcessGroupAtShutdown"
//#define LAUNCH_JOBKEY_POLICIES                      "Policies"
//#define LAUNCH_JOBKEY_ENABLETRANSACTIONS            "EnableTransactions"
