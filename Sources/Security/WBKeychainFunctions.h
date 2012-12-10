/*
 *  WBKeychainFunctions.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WB_KEYCHAIN_FUNCTIONS_H)
#define __WB_KEYCHAIN_FUNCTIONS_H 1

#include <WonderBox/WBBase.h>
#include <Security/Security.h>

WB_EXPORT
OSStatus WBKeychainModifyGenericPassword(SecKeychainItemRef itemRef, CFStringRef service, CFStringRef account, CFStringRef password);
WB_EXPORT
OSStatus WBKeychainFindGenericPassword(CFTypeRef keychain, CFStringRef service, CFStringRef account, CFStringRef *password, SecKeychainItemRef *itemRef);
WB_EXPORT
OSStatus WBKeychainAddGenericPassword(SecKeychainRef keychain, CFStringRef service, CFStringRef account, CFStringRef password, SecKeychainItemRef *itemRef);

WB_EXPORT
OSStatus WBKeychainModifyInternetPassword(SecKeychainItemRef itemRef, CFStringRef server, CFStringRef domain, CFStringRef account,
                                          CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                          CFStringRef password);
WB_EXPORT
OSStatus WBKeychainFindInternetPassword(CFTypeRef keychain, CFStringRef server, CFStringRef domain, CFStringRef account,
                                        CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                        CFStringRef *password, SecKeychainItemRef *itemRef);
WB_EXPORT
OSStatus WBKeychainAddInternetPassword(SecKeychainRef keychain, CFStringRef server, CFStringRef domain, CFStringRef account,
                                       CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                       CFStringRef password, SecKeychainItemRef *itemRef);

#endif /* __WB_KEYCHAIN_FUNCTIONS_H */
