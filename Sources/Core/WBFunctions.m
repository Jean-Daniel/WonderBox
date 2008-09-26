/*
 *  WBFunctions.m
 *  OmniTools
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import WBHEADER(WBFunctions.h)

#include <sys/types.h>
#include <sys/sysctl.h>
#include <libkern/OSAtomic.h>
#include <objc/objc-runtime.h>

#if defined(DEBUG)
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
#warning Deployment Target: Tiger
#elif MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
#warning Deployment Target: Leopard
#endif
#endif

#if defined(__WB_OBJC__)
#pragma mark -
#pragma mark Objective-C Runtime

static
BOOL _WBRuntimeInstanceImplementsSelector(Class cls, SEL sel) {
  unsigned int count = 0;
  Method *methods = class_copyMethodList(cls, &count);
  if (methods) {
    while(count-- > 0) {
      Method method = methods[count];
      if (method_getName(method) == sel) {
				free(methods);
        return YES;
			}
    }
    free(methods);
  }
	return NO;
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5

WB_INLINE
BOOL __WBRuntimeIsSubclass(Class cls, Class parent) {
  NSCParameterAssert(cls);
  Class super = cls;
  do {
    if (super == parent)
      return YES;
  } while (super = class_getSuperclass(super));
  return NO;
}

WB_INLINE
BOOL __WBRuntimeIsDirectSubclass(Class cls, Class parent) {
	return class_getSuperclass(cls) == parent;
}

WB_INLINE
void __WBRuntimeExchangeMethods(Method m1, Method m2) {
  method_exchangeImplementations(m1, m2);
}

WB_INLINE
IMP __WBRuntimeSetMethodImplementation(Method method, IMP addr) {
	return method_setImplementation(method, addr);
}

WB_INLINE
Class __WBRuntimeGetMetaClass(Class cls) {
	return object_getClass(cls);
}

Class WBRuntimeSetObjectClass(id anObject, Class newClass) {
	return object_setClass(anObject, newClass);
}

/* Does not check super class */
BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method) {
	return _WBRuntimeInstanceImplementsSelector(cls, method);
}

#else

WB_INLINE
BOOL __WBRuntimeIsSubclass(Class cls, Class parent) {
  NSCParameterAssert(cls);
  Class super = cls;
  do {
    if (super == parent)
      return YES;
  } while (super = super->super_class);
  return NO;
}

WB_INLINE
BOOL __WBRuntimeIsDirectSubclass(Class cls, Class parent) {
	return cls->super_class == parent;
}

WB_INLINE
void __WBRuntimeExchangeMethods(Method m1, Method m2) {
  if (method_exchangeImplementations) {
		method_exchangeImplementations(m1, m2);
	} else {
		IMP imp = m1->method_imp;
		m1->method_imp = m2->method_imp;
		m2->method_imp = imp;
	}
}

WB_INLINE
IMP __WBRuntimeSetMethodImplementation(Method method, IMP addr) {
	if (method_setImplementation)
		return method_setImplementation(method, addr);
	
	IMP previous = method->method_imp;
	method->method_imp = addr;
	return previous;
}

WB_INLINE
Class __WBRuntimeGetMetaClass(Class cls) {
	return object_getClass ? object_getClass(cls) : cls->isa;
}

Class WBRuntimeSetObjectClass(id anObject, Class newClass) {
	if (object_setClass)
		return object_setClass(anObject, newClass);
	
	/* manual isa swizzling */
	Class previous = anObject->isa;
	anObject->isa = newClass;
	return previous;
}

BOOL WBRuntimeInstanceImplementsSelector(Class cls, SEL method) {
	/* if leopard runtime available */
	if (class_copyMethodList)
		return _WBRuntimeInstanceImplementsSelector(cls, method);
	
	void *iterator = 0;
	struct objc_method_list *methodList;
	//
	// Each call to class_nextMethodList returns one methodList
	//
	while(methodList = class_nextMethodList(cls, &iterator)) {
		int count = methodList->method_count;
		while (count-- > 0) {
			if (methodList->method_list[count].method_name == method)
				return YES;
		}
	}
	return NO;
}

#endif

NSArray *WBRuntimeGetSubclasses(Class parent, BOOL strict) {
	int numClasses;
	Class *classes = NULL;
	numClasses = objc_getClassList(NULL, 0);
	NSMutableArray *result = [NSMutableArray array];
	if (numClasses > 0 ) {
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
		for (int idx = 0; idx < numClasses; idx++) {
			Class cls = classes[idx];
			if (strict) {
				if (__WBRuntimeIsDirectSubclass(cls, parent))
					[result addObject:cls];
			} else if (parent != cls && __WBRuntimeIsSubclass(cls, parent)) {
				[result addObject:cls];
			}				
		}
    free(classes);
	}
	return result;
}

/* Method Swizzling */
static
void _WBRuntimeExchangeMethods(Class class, SEL orig, SEL new, bool instance) {
	Method (*getMethod)(Class, SEL) = instance ? class_getInstanceMethod : class_getClassMethod;
  Method m1 = getMethod(class, orig);
  check(m1 != NULL);
  Method m2 = getMethod(class, new);
  check(m2 != NULL);
	return __WBRuntimeExchangeMethods(m1, m2);
}

void WBRuntimeExchangeClassMethods(Class cls, SEL orig, SEL replace) {
	return _WBRuntimeExchangeMethods(cls, orig, replace, false);
}

void WBRuntimeExchangeInstanceMethods(Class cls, SEL orig, SEL replace) {
	return _WBRuntimeExchangeMethods(cls, orig, replace, true);
}
static
IMP _WBRuntimeSetMethodImplementation(Class cls, SEL sel, IMP addr, bool instance) {
	IMP previous = NULL;
  Method method = instance ? class_getInstanceMethod(cls, sel) : class_getClassMethod(cls, sel);
  if (method)
		previous = __WBRuntimeSetMethodImplementation(method, addr);
  return previous;
}

IMP WBRuntimeSetClassMethodImplementation(Class base, SEL selector, IMP placeholder) {
	return _WBRuntimeSetMethodImplementation(base, selector, placeholder, false);
}
IMP WBRuntimeSetInstanceMethodImplementation(Class base, SEL selector, IMP placeholder) {
	return _WBRuntimeSetMethodImplementation(base, selector, placeholder, true);	
}

BOOL WBRuntimeObjectImplementsSelector(id object, SEL method) {
	return WBRuntimeInstanceImplementsSelector([object class], method);
}

BOOL WBRuntimeClassImplementsSelector(Class cls, SEL method) {
	return WBRuntimeInstanceImplementsSelector(__WBRuntimeGetMetaClass(cls), method);
}

#pragma mark Misc
NSString *WBApplicationGetName() {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey] ? :
	[[NSProcessInfo processInfo] processName];
}

CGRect WBRectScale(CGSize source, CGRect destination, WBScalingMode mode) {
  if (source.width <= 0 || source.height <= 0) return CGRectZero;
  
  CGRect result = CGRectZero;
  result.origin = destination.origin;
  switch (mode) {
    case kWBScalingModeNone:
      result.size.width = source.width;
      result.size.height = source.height;
      break;
    case kWBScalingModeAxesIndependently:
      result = destination;
      break;
      
    case kWBScalingModeProportionallyFitDown:
      if (source.width <= destination.size.width && source.height <= destination.size.height) {
        // if destination size > movie size, do not scale.
        result.size.width = source.width;
        result.size.height = source.height;
        break;
      }
      // else, scale down
    case kWBScalingModeProportionallyFit:
    {
      CGFloat ratio = MIN(destination.size.width / source.width, destination.size.height / source.height);
      result.size.width = source.width * ratio;
      result.size.height = source.height * ratio;
    }
      break;  
      
    case kWBScalingModeProportionallyFillDown:
      if (source.width <= destination.size.width || source.height <= destination.size.height) {
        // if destination size > movie size, do not scale.
        result.size.width = source.width;
        result.size.height = source.height;
        break;
      }      
    case kWBScalingModeProportionallyFill:
    {
      CGFloat ratio = MAX(destination.size.width / source.width, destination.size.height / source.height);
      result.size.width = source.width * ratio;
      result.size.height = source.height * ratio;
      result.origin.x += (destination.size.width - result.size.width) / 2;
      result.origin.y += (destination.size.height - result.size.height) / 2;
    }      
      return result;
  }
  // use integer coordinates to avoid interpolation
  if (result.size.width < destination.size.width) result.origin.x += (destination.size.width - result.size.width) / 2;
  if (result.size.height < destination.size.height) result.origin.y += (destination.size.height - result.size.height)  / 2;
  return result;
}

#endif /* __WB_OBJC__ */

#pragma mark -
#pragma mark Mic
CFStringRef WBCreateStringForOSType(OSType type) {
  type = OSSwapHostToBigInt32(type);
  return (type) ? CFStringCreateWithBytes(kCFAllocatorDefault, (unsigned char *)&type, sizeof(type), kCFStringEncodingMacRoman, FALSE) : nil;
}

OSType WBGetOSTypeFromString(CFStringRef str) {
  OSType result = 0;
  if (str && CFStringGetLength(str) >= 4) {
    CFStringGetBytes(str, CFRangeMake(0, 4), kCFStringEncodingMacRoman, 0, FALSE, (UInt8 *)&result, sizeof(result), NULL);
  }
  return OSSwapBigToHostInt32(result);
}

#pragma mark Versions
SInt32 WBSystemMajorVersion() {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionMajor, &macVersion) == noErr ? macVersion : 0;
}
SInt32 WBSystemMinorVersion() {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionMinor, &macVersion) == noErr ? macVersion : 0;
}
SInt32 WBSystemBugFixVersion() {
  SInt32 macVersion;
  return Gestalt(gestaltSystemVersionBugFix, &macVersion) == noErr ? macVersion : 0;
}

#pragma mark Version Parser

/* According to “Runtime Configuration Guidelines”, we should use short version string */
CFStringRef WBVersionBundleKey = CFSTR("CFBundleShortVersionString");

/* 
 Version number: 
 major.minor.bug[status]build
 - Possible status:
 d: devel
 a: alpha
 b: beta
 rc: release candidate
 f: final ~ r: release
 */
bool WBVersionGetCurrent(CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
	return WBVersionGetBundleVersion(CFBundleGetMainBundle(), major, minor, bug, stage, build);
}

bool WBVersionGetBundleVersion(CFBundleRef bundle, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
	if (!bundle) return false;

  CFStringRef vers = CFBundleGetValueForInfoDictionaryKey(bundle, WBVersionBundleKey);
  if (vers)
    return WBVersionDecompose(vers, major, minor, bug, stage, build);
  return false;
}

bool WBVersionDecompose(CFStringRef version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  if (!version || CFStringGetLength(version) > 64)
    return 0;
  
  bool ok = true;
  char buffer[128];
  CFIndex vers[3] = {0, 0, 0};
  if (CFStringGetCString(version, buffer, 128, kCFStringEncodingUTF8)) {
    CFIndex idx = 0;
    char *ptr = buffer;
    while (*ptr && idx < 3) {
      if (isdigit(*ptr)) {
        vers[idx] *= 10;
        vers[idx] += (*ptr - '0');
      } else {
        idx++;
        if ('.' != *ptr)
          break;
      }
      ptr++;
    }
    if (major) *major = vers[0];
    if (minor) *minor = vers[1];
    if (bug) *bug = vers[2];
    
    /* default values */
    if (stage) *stage = kWBVersionStageFinal;
    if (build) *build = 0;
    /* Check stage */
    if (*ptr) {
      switch (*ptr) {
        case 'd': //devel
        case 'D':
          if (stage) *stage = kWBVersionStageDevelopement;
          break;
					case 'a': // alpha
					case 'A':
          if (stage) *stage = kWBVersionStageAlpha;
          break;
					case 'b': // beta
					case 'B':
          if (stage) *stage = kWBVersionStageBeta;
          break;
					case 'f': // final
					case 'F':
          if (stage) *stage = kWBVersionStageFinal;
          break;
					case 'r': // release or candidate
					case 'R':
          if ('c' == ptr[1] || 'C' == ptr[1]) {
            ptr++;
            if (stage) *stage = kWBVersionStageCandidate;
          } else if (stage) {
            *stage = kWBVersionStageRelease;
          }
          break;
					default:
          // invalid stage
          if (stage) *stage = 0;
          ok = false;
          ptr--;
      }
      ptr++;
      if (*ptr && !isdigit(*ptr)) {
        ok = false;
      } else if (*ptr && build) {
        *build = strtol(ptr, NULL, 10);
      }
    }
  } else {
    ok = false;
  }
  return ok;
}

CFStringRef WBVersionCreateString(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build) {
  CFMutableStringRef str = CFStringCreateMutable(kCFAllocatorDefault, 64);
  CFStringAppendFormat(str, NULL, CFSTR("%lu.%lu"), (long)major, (long)minor);
  if (bug)
    CFStringAppendFormat(str, NULL, CFSTR(".%lu"), (long)bug);
  
  if (build || kWBVersionStageFinal != stage) {
    const char *stg = nil;
    switch (stage) {
      case kWBVersionStageDevelopement:
        stg = "d"; break;
      case kWBVersionStageAlpha:
        stg = "a"; break;
      case kWBVersionStageBeta:
        stg = "b"; break;
      case kWBVersionStageCandidate:
        stg = "rc"; break;        
      case kWBVersionStageFinal:
        stg = "r"; break;
    }
    if (stg && build)
      CFStringAppendFormat(str, NULL, CFSTR("%s%lu"), stg, (long)build);
    else if (stg)
      CFStringAppendFormat(str, NULL, CFSTR("%s"), stg);
  }
  return str;
}

UInt64 WBVersionGetCurrentNumber() {
	return WBVersionGetBundleNumber(CFBundleGetMainBundle());
}

UInt64 WBVersionGetBundleNumber(CFBundleRef bundle) {
	CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;  
  if (WBVersionGetBundleVersion(bundle, &major, &minor, &bug, &stage, &build))
    return WBVersionComposeNumber(major, minor, bug, stage, build);
  return kWBVersionInvalid;
}

UInt64 WBVersionGetNumberFromString(CFStringRef version) {
  CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;
  if (WBVersionDecompose(version, &major, &minor, &bug, &stage, &build))
    return WBVersionComposeNumber(major, minor, bug, stage, build);
  return kWBVersionInvalid;
}

CFStringRef WBVersionCreateStringForNumber(UInt64 version) {
  if (kWBVersionInvalid == version)
    return NULL;
  CFIndex build;
  WBVersionStage stage;
  CFIndex major, minor, bug;
  WBVersionDecomposeNumber(version, &major, &minor, &bug, &stage, &build);
  return WBVersionCreateString(major, minor, bug, stage, build);
}

UInt64 WBVersionComposeNumber(CFIndex major, CFIndex minor, CFIndex bug, WBVersionStage stage, CFIndex build) {
  if (major > 0xffff || minor > 0xffff || bug > 0xffff || stage > 0x7 || build > 0x1fff)
    return kWBVersionInvalid;
  return ((UInt64)major & 0xffff) << 48 | ((UInt64)minor & 0xffff) << 32 | (bug & 0xffff) << 16 | (stage & 0x7) << 13 | (build & 0x1fff);
}

void WBVersionDecomposeNumber(UInt64 version, CFIndex *major, CFIndex *minor, CFIndex *bug, WBVersionStage *stage, CFIndex *build) {
  if (major) *major = (version & 0xffff000000000000) >> 48;
  if (minor) *minor = (version & 0x0000ffff00000000) >> 32;
  if (bug)     *bug = (version & 0x00000000ffff0000) >> 16;
  if (stage) *stage = (version & 0x000000000000e000) >> 13;
  if (build) *build = (version & 0x0000000000001fff);
}

#pragma mark -
CFComparisonResult WBUTCDateTimeCompare(UTCDateTime *t1, UTCDateTime *t2) {
  if (t1->highSeconds < t2->highSeconds) return kCFCompareLessThan;
  else if (t1->highSeconds > t2->highSeconds) return kCFCompareGreaterThan;

  if (t1->lowSeconds < t2->lowSeconds) return kCFCompareLessThan;
  else if (t1->lowSeconds > t2->lowSeconds) return kCFCompareGreaterThan;

  if (t1->fraction < t2->fraction) return kCFCompareLessThan;
  else if (t1->fraction > t2->fraction) return kCFCompareGreaterThan;
  
  return kCFCompareEqualTo;
}

#pragma mark -
#pragma mark Base 16
WB_INLINE
CFIndex __WBHexCharToByte(UniChar ch) {
  if (ch >= '0' && ch <= '9') return ch - '0';
  if (ch >= 'a' && ch <= 'f') return 10 + ch - 'a';
  if (ch >= 'A' && ch <= 'F') return 10 + ch - 'A';
  return -1;
}

CFDataRef WBCFDataCreateFromHexString(CFStringRef str) {
  check(str);
  CFIndex length = CFStringGetLength(str);
  /* String length MUST be even */
  if (length % 2)
    return NULL;
  
  CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, length / 2);
  CFDataSetLength(data, length / 2);
  UInt8 *bytes = CFDataGetMutableBytePtr(data);
  
  bool isValid = true;
  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer(str, &buffer, CFRangeMake(0, length));
  for (CFIndex idx = 0; isValid && idx < length; idx+=2) {
    CFIndex v1 = __WBHexCharToByte(CFStringGetCharacterFromInlineBuffer(&buffer, idx));
    CFIndex v2 = __WBHexCharToByte(CFStringGetCharacterFromInlineBuffer(&buffer, idx + 1));
    if (v1 >= 0 && v2 >= 0)
      *(bytes++) = v1 * 16 + v2;
    else
      isValid = false;
  }
  if (!isValid) {
    CFRelease(data);
    data = NULL;
  }
  return data;
}

#pragma mark Base 64
static 
const UInt8 _WBBase64Table[] = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/', '\0'
};

enum {
  kWBBase64Pad = '=',
};

static
const SInt8 _WBBase64ReverseTable[256] = {
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
  52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
  -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
  -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
  41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
};

CFDataRef WBBase64CreateBase64DataFromBytes(const UInt8 *bytes, CFIndex length) {
  CFDataRef base64 = NULL;
  CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytes, length, kCFAllocatorNull);
  if (data) {
    base64 = WBBase64CreateBase64DataFromData(data);
    CFRelease(data);
  }
  return base64;
}

CFDataRef WBBase64CreateBase64DataFromData(CFDataRef data) {
  check(data);
  const UInt8 *string = CFDataGetBytePtr(data);
  const UInt8 *current = string;
  
  UInt8 *p, *result;
  
  CFIndex length = CFDataGetLength(data);
  CFIndex destLength = ((length + 2) / 3) * 4;
  
  result = CFAllocatorAllocate(kCFAllocatorDefault, destLength * sizeof(UInt8), 0);
  if (!result)
    return NULL;
  
  p = result;
  
  /* keep going until we have less than 24 bits */
  while (length > 2) {
    *p++ = _WBBase64Table[current[0] >> 2];
    *p++ = _WBBase64Table[((current[0] & 0x03) << 4) + (current[1] >> 4)];
    *p++ = _WBBase64Table[((current[1] & 0x0f) << 2) + (current[2] >> 6)];
    *p++ = _WBBase64Table[current[2] & 0x3f];
    
    /* we just handle 3 octets of data */
    current += 3;
    length -= 3; 
  }
  
  /* now deal with the tail end of things */
  if (length != 0) {
    *p++ = _WBBase64Table[current[0] >> 2];
    if (length > 1) {
      *p++ = _WBBase64Table[((current[0] & 0x03) << 4) + (current[1] >> 4)];
      *p++ = _WBBase64Table[(current[1] & 0x0f) << 2];
      *p++ = kWBBase64Pad;
    } else {
      *p++ = _WBBase64Table[(current[0] & 0x03) << 4];
      *p++ = kWBBase64Pad;
      *p++ = kWBBase64Pad;
    }
  }
  
  *p = '\0';
  destLength = (p - result);
  
  return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, result, destLength, kCFAllocatorDefault);
}

CFDataRef WBBase64CreateDataFromBase64Bytes(const UInt8 *bytes, CFIndex length) {
  CFDataRef raw = NULL;
  CFDataRef base64 = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytes, length, kCFAllocatorNull);
  if (base64) {
    raw = WBBase64CreateDataFromBase64Data(base64);
    CFRelease(base64);
  }
  return raw;
}

CFDataRef WBBase64CreateDataFromBase64Data(CFDataRef data) {
  check(data);
  const UInt8 *string = CFDataGetBytePtr(data);
  const UInt8 *current = string;
  int ch, i = 0, j = 0, k;
  
  UInt8 *result;
  CFIndex length = CFDataGetLength(data);
  CFIndex destLength = (length * 3/4) + 1;
  
  result = CFAllocatorAllocate(kCFAllocatorDefault, destLength, 0);
  if (result == NULL) {
    return NULL;
  }
  
  /* run through the whole string, converting as we go */
  while ((ch = *current++) != '\0' && length-- > 0) {
    if (ch == kWBBase64Pad) break;
    
    ch = _WBBase64ReverseTable[ch];
    /* Ignore illegal character */
    if (ch < 0) continue;
    
    switch(i % 4) {
      case 0:
        result[j] = ch << 2;
        break;
      case 1:
        result[j++] |= ch >> 4;
        result[j] = (ch & 0x0f) << 4;
        break;
      case 2:
        result[j++] |= ch >>2;
        result[j] = (ch & 0x03) << 6;
        break;
      case 3:
        result[j++] |= ch;
        break;
    }
    i++;
  }
  
  k = j;
  /* mop things up if we ended on a boundary */
  if (ch == kWBBase64Pad) {
    switch(i % 4) {
      case 1:
        CFAllocatorDeallocate(kCFAllocatorDefault, result);
        return NULL;
      case 2:
        k++;
      case 3:
        result[k++] = 0;
    }
  }
  result[j] = '\0';
  destLength = j;
  
  return CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, result, destLength, kCFAllocatorDefault);
}
