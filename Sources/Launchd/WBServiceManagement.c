/*
 *  WBServiceManagement.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include "WBServiceManagement.h"

#include <launch.h>
#include <unistd.h>

#include <CoreServices/CoreServices.h>

// MARK: Core Foundation -> Launchd
static
launch_data_t _WBServiceNewDataFromObject(CFTypeRef obj);

static
launch_data_t _WBServiceNewDataFromArray(CFArrayRef dict);
static
launch_data_t _WBServiceNewDataDictionary(CFDictionaryRef dict);

// MARK: Launchd -> Core Foundation
static 
CFTypeRef _WBServiceCreateObjectFromData(const launch_data_t data);

static 
CFArrayRef _WBServiceCreateArrayFromData(const launch_data_t data);
static 
CFDictionaryRef _WBServiceCreateDictionaryFromData(const launch_data_t data);

// MARK: Message Send
static 
OSStatus _WBServiceSendMessage(launch_data_t request, launch_data_t *outResponse);
static
Boolean _WBServiceSendSimpleMessage(CFStringRef name, const char *msg, launch_data_t *outResponse, CFErrorRef *outError);
static
CFTypeRef _WBServiceSendSimpleMessage2(CFStringRef name, const char *msg, CFErrorRef *outError);

// MARK: String Utilities
static 
void _WBServiceGetString(const char *str, size_t length, void *ctxt);
static
OSStatus _WBCFStringGetBytes(CFStringRef str, CFStringEncoding encoding, void (*cb)(const char *, size_t, void*), void *ctxt);

// MARK: launchd API
Boolean WBServiceRegisterJob(CFDictionaryRef job, CFErrorRef *outError) {
//  if (SMJobSubmit)
//    return SMJobSubmit(kSMDomainUserLaunchd, job, NULL, outError);
  launch_data_t ljob = _WBServiceNewDataDictionary(job);
  OSStatus err = ljob ? noErr : paramErr;
  
  if (noErr == err) {
    launch_data_t request = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
    if (request) {
      if (launch_data_dict_insert(request, ljob, LAUNCH_KEY_SUBMITJOB)) {
        err = _WBServiceSendMessage(request, NULL);
        ljob = NULL;
      } else {
        err = -1;
      }
      launch_data_free(request);
    } else {
      err = memFullErr; 
    }
  }
  if (ljob) // something wrong
    launch_data_free(ljob);
  
  if (noErr != err) {
    if (outError) 
      *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainOSStatus, err, NULL);
  }
  
  return noErr == err;
}
Boolean WBServiceUnregisterJob(CFStringRef name, CFErrorRef *outError) {
//  if (SMJobRemove)
//    return SMJobRemove(kSMDomainUserLaunchd, name, NULL, outError);
  return _WBServiceSendSimpleMessage(name, LAUNCH_KEY_REMOVEJOB, NULL, outError);
}

Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError) {
  return _WBServiceSendSimpleMessage(name, LAUNCH_KEY_STARTJOB, NULL, outError);
}

Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError) {
  return _WBServiceSendSimpleMessage(name, LAUNCH_KEY_STOPJOB, NULL, outError);
}

CFDictionaryRef WBServiceCopyJob(CFStringRef name, CFErrorRef *outError) {
  return _WBServiceSendSimpleMessage2(name, LAUNCH_KEY_GETJOB, outError);
}

CFTypeRef WBServiceCheckIn(CFErrorRef *outError) {
  return _WBServiceSendSimpleMessage2(NULL, LAUNCH_KEY_CHECKIN, outError);
}
launch_data_t WBServiceCheckIn2(CFErrorRef *outError) {
  launch_data_t response;
  if (!_WBServiceSendSimpleMessage(NULL, LAUNCH_KEY_CHECKIN, &response, outError))
    return NULL;
  return response;
}

// MARK: Serialization
launch_data_t _WBServiceNewDataFromObject(CFTypeRef obj) {
  if (!obj) return NULL;
  
  CFTypeID type = CFGetTypeID(obj);
  if (CFDictionaryGetTypeID() == type) {
    return _WBServiceNewDataDictionary(obj);
  } else if (CFArrayGetTypeID() == type) {
    return _WBServiceNewDataFromArray(obj);
  } else if (CFNumberGetTypeID() == type) {
    if (CFNumberIsFloatType(obj)) { 
      double num;
      if (CFNumberGetValue(obj, kCFNumberDoubleType, &num))
        return launch_data_new_real(num); // LAUNCH_DATA_REAL
    } else { 
      long long num;
      if (CFNumberGetValue(obj, kCFNumberLongLongType, &num))
        return launch_data_new_integer(num); // LAUNCH_DATA_INTEGER,
    }
    return NULL;
  } else if (CFBooleanGetTypeID() == type) {
    return launch_data_new_bool(CFBooleanGetValue(obj)); // LAUNCH_DATA_BOOL
  } else if (CFStringGetTypeID() == type) {
    launch_data_t str = NULL;
    if (noErr == _WBCFStringGetBytes(obj, kCFStringEncodingUTF8, _WBServiceGetString, &str))
      return str; // LAUNCH_DATA_STRING
    return NULL;
  } 
  // Unsupported type
  return NULL;
}

struct _WBSerializeContext {
  bool error;
  launch_data_t dict;
  launch_data_t value;
};
static void __WBSerializeInsert(const char *str, size_t length, void *context) {
  struct _WBSerializeContext *ctxt = (struct _WBSerializeContext *)context;
  if (!launch_data_dict_insert(ctxt->dict, ctxt->value, str)) {
    launch_data_free(ctxt->value);
    ctxt->error = true;
  }
  ctxt->value = NULL;
}

static void __WBSerializeDictEntry(const void *key, const void *value, void *context) {
  struct _WBSerializeContext *ctxt = (struct _WBSerializeContext *)context;
  if (CFGetTypeID(key) != CFStringGetTypeID()) {
    ctxt->error = true;
    return;
  }
  
  ctxt->value = _WBServiceNewDataFromObject(value);
  if (ctxt->value) 
    _WBCFStringGetBytes(key, kCFStringEncodingUTF8, __WBSerializeInsert, context);
  else
    ctxt->error = true;
}

launch_data_t _WBServiceNewDataDictionary(CFDictionaryRef value) {
  //    LAUNCH_DATA_DICTIONARY
  struct _WBSerializeContext ctxt = {
    .error = false,
    .dict = launch_data_alloc(LAUNCH_DATA_DICTIONARY),
    .value = NULL
  };
  CFDictionaryApplyFunction(value, __WBSerializeDictEntry, &ctxt);
  if (ctxt.error) {
    launch_data_free(ctxt.dict);
    ctxt.dict = NULL;
  }
  return ctxt.dict;
}
launch_data_t _WBServiceNewDataFromArray(CFArrayRef value) {
  //    LAUNCH_DATA_ARRAY
  size_t oidx = 0; // out index
  bool error = false;
  launch_data_t array = launch_data_alloc(LAUNCH_DATA_ARRAY);
  for (CFIndex idx = 0, count = CFArrayGetCount(value); !error && idx < count; ++idx) {
    CFTypeRef item = CFArrayGetValueAtIndex(value, idx);
    launch_data_t data = _WBServiceNewDataFromObject(item);
    if (data) {
      if (!launch_data_array_set_index(array, data, oidx++)) {
        launch_data_free(data);
        error = true;
      }
    } else {
      error = true;
    }
  }
  if (error) {
    launch_data_free(array);
    array = NULL;
  }
  return array;
}

// MARK: Message Send
OSStatus _WBServiceSendMessage(launch_data_t request, launch_data_t *outResponse) {
  OSStatus err = noErr;
  launch_data_t response;
  if ((response = launch_msg(request)) == NULL) {
    err = kPOSIXErrorBase + errno;
  } else {
    switch (launch_data_get_type(response)) {
        // launchd will return an errno if an error occurs
      case LAUNCH_DATA_ERRNO:
        err = kPOSIXErrorBase + launch_data_get_errno(response);
        if (err == kPOSIXErrorBase) err = noErr;
        launch_data_free(response);
        break;        
      default:
        if (outResponse) 
          *outResponse = response;
        else
          launch_data_free(response);
        break;
    }
  }
  return err;
}

Boolean _WBServiceSendSimpleMessage(CFStringRef name, const char *msg, launch_data_t *response, CFErrorRef *outError) {
  OSStatus err = noErr;
  launch_data_t request;
  if (name) {
    launch_data_t str = NULL;
    request = launch_data_alloc(LAUNCH_DATA_DICTIONARY); 
    if (!request) err = memFullErr;
    if (noErr == err)
      err = _WBCFStringGetBytes(name, kCFStringEncodingUTF8, _WBServiceGetString, &str);
    if (noErr == err) {
      if (!launch_data_dict_insert(request, str, msg)) {
        err = kPOSIXErrorBase + errno;
        launch_data_free(str);
      }
    }
  } else {
    // no job name
    request = launch_data_new_string(msg);
    if (!request) err = memFullErr;
  }
  
  if (noErr == err) 
    err = _WBServiceSendMessage(request, response);

  if (request)
    launch_data_free(request);

  if (noErr != err) {
    if (outError) 
      *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainOSStatus, err, NULL);
  }
  
  return noErr == err;
}

CFTypeRef _WBServiceSendSimpleMessage2(CFStringRef name, const char *msg, CFErrorRef *outError) {
  launch_data_t response;
  CFTypeRef service = NULL;
  if (!_WBServiceSendSimpleMessage(name, msg, &response, outError))
    return NULL;

  OSStatus err = noErr;
  if (response) {
    service = _WBServiceCreateObjectFromData(response);
    if (!service) 
      err = coreFoundationUnknownErr;
    launch_data_free(response);
  } else {
    err = -1;
  }
  if (noErr != err && outError)
    *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainOSStatus, err, NULL);
  return service;
}

// MARK: String Utilities 
void _WBServiceGetString(const char *str, size_t length, void *ctxt) {
  launch_data_t *string = (launch_data_t *)ctxt;
  if (string)
    *string = launch_data_new_string(str);
}

// [NSString UTF8String] without cocoa and autorelease
OSStatus _WBCFStringGetBytes(CFStringRef str, CFStringEncoding encoding, void (*cb)(const char *, size_t, void*), void *ctxt) {
  if (!str || !cb) return paramErr;
  
  const char *string;
  OSStatus result = noErr;
  if ((string = CFStringGetCStringPtr(str, encoding))) {
    cb(string, strlen(string), ctxt);
  } else {
#define kStackBufferSize 4096
    char stack[kStackBufferSize];
    char *buffer = stack;
    /* Get approximative size */
    CFIndex length = CFStringGetMaximumSizeForEncoding(CFStringGetLength(str), encoding);
    /* If length > kStackBufferSize, check the real size */
    if (length >= kStackBufferSize) {
      length = CFStringGetBytes(str, CFRangeMake(0, CFStringGetLength(str)), encoding, 0, FALSE, NULL, 0, &length);
      if (length < 0) {
        result = kTextUndefinedElementErr;
      } else if (length >= kStackBufferSize) {
        /* If real size > stack buffer, allocate a true heap buffer */
        length++; /* null terminate string */
        buffer = CFAllocatorAllocate(kCFAllocatorDefault, length * sizeof(*buffer), 0);
      } else {
        /* Set length to max stack buffer size */
        length = kStackBufferSize;
      }
    } else {
      /* Set length to max stack buffer size */
      length = kStackBufferSize;
    }
    if (length > 0) {
      if (CFStringGetBytes(str, CFRangeMake(0, CFStringGetLength(str)), encoding, 0, false, (UInt8 *)buffer, length - 1, &length)) {
        buffer[length] = '\0'; // GetBytes does not append zero at buffer end.
        cb(buffer, length, ctxt);
      } else {
        result = kTextUndefinedElementErr;
      }
    } 
    if (buffer != stack) CFAllocatorDeallocate(kCFAllocatorDefault, buffer);
  }
  return result;
}

// MARK: -
CFTypeRef _WBServiceCreateObjectFromData(const launch_data_t data) {
  if (!data) return NULL;
  CFTypeRef object = NULL;
  switch (launch_data_get_type(data)) {
    case LAUNCH_DATA_DICTIONARY:
      object = _WBServiceCreateDictionaryFromData(data);
      break;
    case LAUNCH_DATA_ARRAY:
      object = _WBServiceCreateArrayFromData(data);
      break;
    case LAUNCH_DATA_FD:
      object = CFFileDescriptorCreate(kCFAllocatorDefault, launch_data_get_fd(data), false, NULL, NULL) ? : (CFTypeRef)kCFNull;
      break;
    case LAUNCH_DATA_INTEGER: {
      long long value = launch_data_get_integer(data);
      object = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &value);
    }
      break;
    case LAUNCH_DATA_REAL: {
      double value = launch_data_get_real(data);
      object = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &value);      
    }
      break;      
    case LAUNCH_DATA_BOOL:
      object = CFRetain(launch_data_get_bool(data) ? kCFBooleanTrue : kCFBooleanFalse);
      break;
    case LAUNCH_DATA_STRING:
      object = CFStringCreateWithCString(kCFAllocatorDefault, launch_data_get_string(data), kCFStringEncodingUTF8);
      break;
    case LAUNCH_DATA_OPAQUE:
      object = CFDataCreate(kCFAllocatorDefault, launch_data_get_opaque(data), launch_data_get_opaque_size(data));
      break;
    case LAUNCH_DATA_ERRNO:
      object = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, launch_data_get_errno(data), NULL);
      break;
    case LAUNCH_DATA_MACHPORT:
      object = CFMachPortCreateWithPort(kCFAllocatorDefault, launch_data_get_machport(data), NULL, NULL, NULL) ? : (CFTypeRef)kCFNull;
      break;
  }
  return object;
}

//static 
//void __WBServiceCleanupObject(const void *key, const void *value, void *ctxt) {
//  // Dictionary callback
//  WBServiceCleanupObject(value);
//}

//void WBServiceCleanupObject(CFTypeRef object) {
//  if (!object) return;
//  CFTypeID type = CFGetTypeID(object);
//  if (CFDictionaryGetTypeID() == type) {
//    CFDictionaryApplyFunction(object, __WBServiceCleanupObject, NULL);
//  } else if (CFArrayGetTypeID() == type) {
//    for (CFIndex idx = 0, count = CFArrayGetCount(object); idx < count; ++idx)
//      WBServiceCleanupObject(CFArrayGetValueAtIndex(object, idx));
//  } else if (CFFileDescriptorGetTypeID() == type) {
//    // close file descriptor (as we init it with 'do not close on invalidate')
//    close(CFFileDescriptorGetNativeDescriptor((CFFileDescriptorRef)object));
//    // Note: invalidate set fd to -1 but does not close it.
//    CFFileDescriptorInvalidate((CFFileDescriptorRef)object);
//  } else if (CFMachPortGetTypeID() == type) {
//    CFMachPortInvalidate((CFMachPortRef)object); // optional as the mach port object listen death notifications
//    mach_port_destroy(mach_task_self(), CFMachPortGetPort((CFMachPortRef)object));
//  }
//}

CFArrayRef _WBServiceCreateArrayFromData(const launch_data_t data) {
  CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, launch_data_array_get_count(data), &kCFTypeArrayCallBacks);
  for (size_t idx = 0, count = launch_data_array_get_count(data); idx < count; ++idx) {
    CFTypeRef item = _WBServiceCreateObjectFromData(launch_data_array_get_index(data, idx));
    if (item) {
      CFArrayAppendValue(array, item);
      CFRelease(item);
    } else {
      //WBServiceCleanupObject(array);
      CFRelease(array);
      array = NULL;
      break;
    }
  }
  return array;
}

static
void __WBServiceCreateDictionary(const launch_data_t value, const char *key, void *ctxt) {
  CFMutableDictionaryRef *dict = (CFMutableDictionaryRef *)ctxt;
  if (!*dict) return;
  
  bool ok = false;
  CFStringRef str = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
  if (str) {
    CFTypeRef obj = _WBServiceCreateObjectFromData(value);
    if (obj) {
      CFDictionarySetValue(*dict, str, obj);
      CFRelease(obj);
      ok = true;
    }
    CFRelease(str);
  }
  if (!ok) {
    //WBServiceCleanupObject(*dict);
    CFRelease(*dict);
    *dict = NULL;
  }
}

CFDictionaryRef _WBServiceCreateDictionaryFromData(const launch_data_t data) {
  CFMutableDictionaryRef dict = CFDictionaryCreateMutable(kCFAllocatorDefault, launch_data_dict_get_count(data), 
                                                          &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  launch_data_dict_iterate(data, __WBServiceCreateDictionary, &dict);
  return dict;
}
