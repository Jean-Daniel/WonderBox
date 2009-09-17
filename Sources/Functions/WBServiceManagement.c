//
//  WBServiceManagement.m
//  bootstrap
//
//  Created by Jean-Daniel Dupas on 17/09/09.
//  Copyright 2009 Ninsight. All rights reserved.
//

#import WBHEADER(WBServiceManagement.h)

#include <launch.h>

// MARK: Serialization
static
launch_data_t _WBServiceSerializeObject(CFTypeRef obj);

static
launch_data_t _WBServiceSerializeDictionary(CFDictionaryRef dict);
static
launch_data_t _WBServiceSerializeArray(CFArrayRef dict);
static
launch_data_t _WBServiceSerializeNumber(CFNumberRef dict);
static
launch_data_t _WBServiceSerializeBoolean(CFBooleanRef dict);
static
launch_data_t _WBServiceSerializeString(CFStringRef dict);

// MARK: Message Send
static 
OSStatus _WBServiceSendMessage(launch_data_t request, launch_data_t *outResponse);
static
Boolean _WBServiceSendSimpleJobMessage(CFStringRef name, CFErrorRef *outError, const char *msg);

// MARK: String Utilities
static 
void _WBServiceGetString(const char *str, size_t length, void *ctxt);
static
OSStatus _WBCFStringGetBytes(CFStringRef str, CFStringEncoding encoding, void (*cb)(const char *, size_t, void*), void *ctxt);

// MARK: launchd API
Boolean WBServiceSubmitJob(CFDictionaryRef job, CFErrorRef *outError) {
  //  if (SMJobSubmit)
  //    return SMJobSubmit(kSMDomainUserLaunchd, job, NULL, outError);
  launch_data_t ljob = _WBServiceSerializeDictionary(job);
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
Boolean WBServiceRemoveJob(CFStringRef name, CFErrorRef *outError) {
  //  if (SMJobRemove)
  //    return SMJobRemove(kSMDomainUserLaunchd, name, NULL, outError);
  return _WBServiceSendSimpleJobMessage(name, outError, LAUNCH_KEY_REMOVEJOB);
}

Boolean WBServiceStartJob(CFStringRef name, CFErrorRef *outError) {
  return _WBServiceSendSimpleJobMessage(name, outError, LAUNCH_KEY_STARTJOB);
}

Boolean WBServiceStopJob(CFStringRef name, CFErrorRef *outError) {
  return _WBServiceSendSimpleJobMessage(name, outError, LAUNCH_KEY_STOPJOB);
}

// MARK: Serialization
launch_data_t _WBServiceSerializeObject(CFTypeRef obj) {
  if (!obj) return NULL;
  
  CFTypeID type = CFGetTypeID(obj);
  if (CFDictionaryGetTypeID() == type) {
    return _WBServiceSerializeDictionary(obj);
  } else if (CFArrayGetTypeID() == type) {
    return _WBServiceSerializeArray(obj);
  } else if (CFNumberGetTypeID() == type) {
    return _WBServiceSerializeNumber(obj);
  } else if (CFBooleanGetTypeID() == type) {
    return _WBServiceSerializeBoolean(obj);
  } else if (CFStringGetTypeID() == type) {
    return _WBServiceSerializeString(obj);
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
  
  ctxt->value = _WBServiceSerializeObject(value);
  if (ctxt->value) 
    _WBCFStringGetBytes(key, kCFStringEncodingUTF8, __WBSerializeInsert, context);
  else
    ctxt->error = true;
}

launch_data_t _WBServiceSerializeDictionary(CFDictionaryRef value) {
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
launch_data_t _WBServiceSerializeArray(CFArrayRef value) {
  //    LAUNCH_DATA_ARRAY
  size_t oidx = 0; // out index
  bool error = false;
  launch_data_t array = launch_data_alloc(LAUNCH_DATA_ARRAY);
  for (CFIndex idx = 0, count = CFArrayGetCount(value); !error && idx < count; idx++) {
    CFTypeRef item = CFArrayGetValueAtIndex(value, idx);
    launch_data_t data = _WBServiceSerializeObject(item);
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

launch_data_t _WBServiceSerializeNumber(CFNumberRef value) {
  if (CFNumberIsFloatType(value)) { // LAUNCH_DATA_REAL
    double num;
    if (CFNumberGetValue(value, kCFNumberDoubleType, &num))
      return launch_data_new_real(num);    
  } else { // LAUNCH_DATA_INTEGER,
    long long num;
    if (CFNumberGetValue(value, kCFNumberLongLongType, &num))
      return launch_data_new_integer(num);
  }
  return NULL;
}
launch_data_t _WBServiceSerializeBoolean(CFBooleanRef value) {
  //		LAUNCH_DATA_BOOL
  return launch_data_new_bool(CFBooleanGetValue(value));
}
launch_data_t _WBServiceSerializeString(CFStringRef value) {
  //		LAUNCH_DATA_STRING
  launch_data_t str = NULL;
  if (noErr == _WBCFStringGetBytes(value, kCFStringEncodingUTF8, _WBServiceGetString, &str))
    return str;
  return NULL;
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

Boolean _WBServiceSendSimpleJobMessage(CFStringRef name, CFErrorRef *outError, const char *msg) {
  launch_data_t str = NULL;
  launch_data_t request = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
  OSStatus err = _WBCFStringGetBytes(name, kCFStringEncodingUTF8, _WBServiceGetString, &str);
  if (noErr == err) {
    launch_data_dict_insert(request, str, msg);
    err = _WBServiceSendMessage(request, NULL);    
  }

  if (noErr != err) {
    if (outError) 
      *outError = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainOSStatus, err, NULL);
  }
  launch_data_free(request);
  return noErr == err;
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
  if (string = CFStringGetCStringPtr(str, encoding)) {
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
