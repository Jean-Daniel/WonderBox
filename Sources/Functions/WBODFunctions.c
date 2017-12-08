/*
 *  WBODFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include <WonderBox/WBODFunctions.h>

#include <pwd.h>
#include <grp.h>

CFStringRef WBODCopyUserNameForUID(uid_t uid) {
  CFStringRef name = NULL;
  struct passwd *user = getpwuid(uid);
  if (user && user->pw_name) {
    name = CFStringCreateWithCString(kCFAllocatorDefault, user->pw_name, kCFStringEncodingUTF8);
  }
  return name;
}
CFStringRef WBODCopyGroupNameForGID(gid_t gid) {
  CFStringRef name = NULL;
  struct group *gpr = getgrgid(gid);
  if (gpr && gpr->gr_name) {
    name = CFStringCreateWithCString(kCFAllocatorDefault, gpr->gr_name, kCFStringEncodingUTF8);
  }
  return name;
}

uid_t WBODGetUIDForUserName(CFStringRef user) {
  uid_t uid = -1;
  char stack[256];
  const char *name = CFStringGetCStringPtr(user, kCFStringEncodingUTF8);
  if (!name && CFStringGetCString(user, stack, 256, kCFStringEncodingUTF8)) {
    name = stack;
  }
  if (name) {
    struct passwd *passwd = getpwnam(name);
    if (passwd) {
      uid = passwd->pw_uid;
    }
  }
  return uid;
}
gid_t WBODGetGIDForGroupName(CFStringRef group) {
  gid_t gid = -1;
  char stack[256];
  const char *name = CFStringGetCStringPtr(group, kCFStringEncodingUTF8);
  if (!name && CFStringGetCString(group, stack, 256, kCFStringEncodingUTF8)) {
    name = stack;
  }
  if (name) {
    struct group *gpr = getgrnam(name);
    if (gpr) {
      gid = gpr->gr_gid;
    }
  }
  return gid;
}

// MARK: -
// MARK: Open Directory
CFTypeRef WBODRecordCopyFirstValue(ODRecordRef record, ODAttributeType attribute) {
  CFArrayRef values = ODRecordCopyValues(record, attribute, NULL);
  if (!values) return NULL;

  CFTypeRef result = NULL;
  if (CFArrayGetCount(values) > 0)
    result = CFRetain(CFArrayGetValueAtIndex(values, 0));

  CFRelease(values);
  return result;
}

static
CFTypeRef _WBODDetailsGetDefaultValue(CFDictionaryRef details, ODAttributeType attribute) {
  CFArrayRef values = CFDictionaryGetValue(details, attribute);
  if (!values) return NULL;

  if (CFArrayGetCount(values) > 0)
    return CFArrayGetValueAtIndex(values, 0);

  return NULL;
}

CFDictionaryRef WBODRecordCopyAttributes(ODRecordRef record, CFArrayRef attributes) {
  CFDictionaryRef values = ODRecordCopyDetails(record, attributes, NULL);
  if (!values) return NULL;

  CFMutableDictionaryRef user = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                          &kCFCopyStringDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);

  for (CFIndex idx = 0, count = CFArrayGetCount(attributes); idx < count; ++idx) {
    ODAttributeType key = CFArrayGetValueAtIndex(attributes, idx);
    CFTypeRef value = _WBODDetailsGetDefaultValue(values, key);
    if (value)
      CFDictionarySetValue(user, key, value);
  }
  CFRelease(values);

  return user;
}

CFArrayRef WBODCopyVisibleUsersAttributes(ODAttributeType attribute, ...) {
  assert(attribute);

  CFArrayRef required = CFArrayCreate(kCFAllocatorDefault, (const void **)(ODAttributeType[]) {
    kODAttributeTypePassword,
    kODAttributeTypeUserShell
  }, 2, &kCFTypeArrayCallBacks);

  CFErrorRef error;
  ODQueryRef query = ODQueryCreateWithNodeType(kCFAllocatorDefault, kODNodeTypeLocalNodes, kODRecordTypeUsers,
                                               kODAttributeTypeAllAttributes, kODMatchAny, NULL,
                                               required, 0, &error);
  CFRelease(required);

  if (!query) {
    CFRelease(error);
    return NULL;
  }

  CFArrayRef records = ODQueryCopyResults(query, false, &error);
  CFRelease(query);
  if (!records) {
    if (error)
      CFRelease(error);
    return NULL;
  }

  va_list args;
  va_start(args, attribute);
  CFMutableArrayRef requested = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
  CFStringRef attr = attribute;
  do {
    CFArrayAppendValue(requested, attr);
    attr = va_arg(args, CFStringRef);
  } while (attr);
  va_end(args);

  CFMutableArrayRef users = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

  for (CFIndex idx = 0, count = CFArrayGetCount(records); idx < count; ++idx) {
    ODRecordRef record = (ODRecordRef)CFArrayGetValueAtIndex(records, idx);
    CFStringRef shell = WBODRecordCopyFirstValue(record, kODAttributeTypeUserShell);
    if (shell && !CFEqual(shell, CFSTR("/usr/bin/false"))) {
      CFStringRef passwd = WBODRecordCopyFirstValue(record, kODAttributeTypePassword);
      if (passwd && !CFEqual(passwd, CFSTR("*"))) {
        CFDictionaryRef user = WBODRecordCopyAttributes(record, requested);
        if (user) {
          CFArrayAppendValue(users, user);
          CFRelease(user);
        }
      }
      if (passwd) CFRelease(passwd);
    }
    if (shell) CFRelease(shell);
  }

  CFRelease(requested);
  CFRelease(records);
  return users;
}

CFTypeRef WBODCopyUserAttribute(CFStringRef username, ODAttributeType attribute) {
  assert(username && attribute);
  if (!username || !attribute)
    return NULL;

  CFErrorRef error;
  ODQueryRef query = ODQueryCreateWithNodeType(kCFAllocatorDefault, kODNodeTypeLocalNodes, kODRecordTypeUsers,
                                               kODAttributeTypeRecordName, kODMatchEqualTo, username,
                                               attribute, 0, &error);

  CFArrayRef records = ODQueryCopyResults(query, false, &error);
  CFRelease(query);
  if (!records) {
    if (error)
      CFRelease(error);
    return NULL;
  }

  CFTypeRef result = NULL;
  if (CFArrayGetCount(records) >= 1) {
    ODRecordRef user = (ODRecordRef)CFArrayGetValueAtIndex(records, 0);
    result = WBODRecordCopyFirstValue(user, attribute);
  }
  CFRelease(records);

  return result;
}

CFDictionaryRef WBODCopyUserAttributes(CFStringRef username, ODAttributeType attribute, ...) {
  assert(username && attribute);
  if (!username || !attribute)
    return NULL;

  CFMutableArrayRef attributes = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
  if (!attributes)
    return NULL;

  va_list args;
  va_start(args, attribute);
  do {
    CFArrayAppendValue(attributes, attribute);
    attribute = va_arg(args, ODAttributeType);
  } while (attribute);
  va_end(args);

  CFErrorRef error;
  ODQueryRef query = ODQueryCreateWithNodeType(kCFAllocatorDefault, kODNodeTypeLocalNodes, kODRecordTypeUsers,
                                               kODAttributeTypeRecordName, kODMatchEqualTo, username,
                                               attributes, 0, &error);

  CFArrayRef records = ODQueryCopyResults(query, false, &error);
  CFRelease(query);
  if (!records) {
    CFRelease(attributes);
    if (error)
      CFRelease(error);
    return NULL;
  }

  CFMutableDictionaryRef result = NULL;
  if (CFArrayGetCount(records) >= 1) {
    result = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                       &kCFCopyStringDictionaryKeyCallBacks,
                                       &kCFTypeDictionaryValueCallBacks);

    ODRecordRef user = (ODRecordRef)CFArrayGetValueAtIndex(records, 0);

    for (CFIndex idx = 0, count = CFArrayGetCount(attributes); idx < count; ++idx) {
      CFStringRef attr = CFArrayGetValueAtIndex(attributes, idx);
      CFTypeRef value = WBODRecordCopyFirstValue(user, attr);
      if (value) {
        CFDictionarySetValue(result, attr, value);
        CFRelease(value);
      }
    }
  }
  CFRelease(records);

  CFRelease(attributes);

  return result;
}
