/*
 *  WBKeychainFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#include WBHEADER(WBKeychainFunctions.h)

WB_INLINE
UTF8Char *__WBCFStringCopyUTF8Characters(CFStringRef string) {
  CFIndex length = CFStringGetMaximumSizeForEncoding(CFStringGetLength(string), kCFStringEncodingUTF8);
  UTF8Char *characters = calloc(length, sizeof(UTF8Char));
  if (!characters) return NULL;

  if (!CFStringGetCString(string, (char *)characters, length, kCFStringEncodingUTF8)) {
    free(characters);
    return NULL;
  }
  return characters;
}

OSStatus WBKeychainFindGenericPassword(CFTypeRef keychain, CFStringRef service, CFStringRef account, CFStringRef *password, SecKeychainItemRef *itemRef) {
  OSStatus status;
  if (password) *password = NULL;
  char *serviceStr = (char *)__WBCFStringCopyUTF8Characters(service);
  char *accountStr = (char *)__WBCFStringCopyUTF8Characters(account);
  require_action_string(serviceStr != NULL && accountStr != NULL, bail, status = paramErr, "Unable to get service or account characters");

  UInt32 length;
  UTF8Char *passwordStr;
  status = SecKeychainFindGenericPassword(keychain,
                                          (UInt32)strlen(serviceStr), serviceStr,
                                          (UInt32)strlen(accountStr), accountStr,
                                          password ? &length : NULL,
                                          password ? (void **)&passwordStr : NULL,
                                          itemRef);
  if ((noErr == status) && password) {
    *password = CFStringCreateWithBytes(kCFAllocatorDefault, passwordStr, length, kCFStringEncodingUTF8, FALSE);
    SecKeychainItemFreeContent(NULL, passwordStr);
  }

bail:
    if (serviceStr) free(serviceStr);
  if (accountStr) free(accountStr);
  return status;
}

OSStatus WBKeychainFindInternetPassword(CFTypeRef keychain, CFStringRef server, CFStringRef domain, CFStringRef account,
                                        CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                        CFStringRef *password, SecKeychainItemRef *itemRef) {
  OSStatus status;
  if (password) *password = NULL;
  /* Get server and account characters */
  char *pathStr = NULL;
  char *domainStr = NULL;

  char *serverStr = (char *)__WBCFStringCopyUTF8Characters(server);
  char *accountStr = (char *)__WBCFStringCopyUTF8Characters(account);
  require_action_string(serverStr != NULL && accountStr != NULL, bail, status = paramErr, "Unable to get service or account characters");
  /* Get optionals parameters characters */
  pathStr = path ? (char *)__WBCFStringCopyUTF8Characters(path) : NULL;
  domainStr = domain ? (char *)__WBCFStringCopyUTF8Characters(domain) : NULL;

  UInt32 length;
  UTF8Char *passwordStr;
  status =  SecKeychainFindInternetPassword(keychain,
                                            (UInt32)strlen(serverStr), serverStr,
                                            domainStr ? (UInt32)strlen(domainStr) : 0, domainStr ? : NULL,
                                            (UInt32)strlen(accountStr), accountStr,
                                            pathStr ? (UInt32)strlen(pathStr) : 0, pathStr ? : NULL,
                                            port, protocol, authenticationType,
                                            password ? &length : NULL,
                                            password ? (void **)&passwordStr : NULL,
                                            itemRef);
  if ((noErr == status) && password) {
    *password = CFStringCreateWithBytes(kCFAllocatorDefault, passwordStr, length, kCFStringEncodingUTF8, FALSE);
    SecKeychainItemFreeContent(NULL, passwordStr);
  }

bail:
    if (serverStr) free(serverStr);
  if (accountStr) free(accountStr);
  if (pathStr) free(pathStr);
  if (domainStr) free(domainStr);
  return status;
}


//Call SecKeychainAddGenericPassword to add a new password to the keychain:
OSStatus WBKeychainAddGenericPassword(SecKeychainRef keychain, CFStringRef service, CFStringRef account, CFStringRef password, SecKeychainItemRef *itemRef) {
  OSStatus status;
  char *serviceStr = (char *)__WBCFStringCopyUTF8Characters(service);
  char *accountStr = (char *)__WBCFStringCopyUTF8Characters(account);
  char *passwordStr = (char *)__WBCFStringCopyUTF8Characters(password);
  require_action_string(serviceStr != NULL && accountStr != NULL && passwordStr != NULL, bail, status = paramErr, "Unable to get service or account characters");

  status = SecKeychainAddGenericPassword(keychain,
                                         (UInt32)strlen(serviceStr), serviceStr,
                                         (UInt32)strlen(accountStr), accountStr,
                                         (UInt32)strlen(passwordStr), passwordStr,
                                         itemRef);

bail:
    if (serviceStr) free(serviceStr);
  if (accountStr) free(accountStr);
  if (passwordStr) free(passwordStr);
  return status;
}

OSStatus WBKeychainAddInternetPassword(SecKeychainRef keychain, CFStringRef server, CFStringRef domain, CFStringRef account,
                                       CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                       CFStringRef password, SecKeychainItemRef *itemRef) {
  OSStatus status;

  char *pathStr = NULL;
  char *domainStr = NULL;
  char *serverStr = (char *)__WBCFStringCopyUTF8Characters(server);
  char *accountStr = (char *)__WBCFStringCopyUTF8Characters(account);
  char *passwordStr = (char *)__WBCFStringCopyUTF8Characters(password);
  require_action_string(serverStr != NULL && accountStr != NULL && passwordStr != NULL, bail, status = paramErr, "Unable to get service or account characters");

  /* Get optionals parameters characters */
  pathStr = path ? (char *)__WBCFStringCopyUTF8Characters(path) : NULL;
  domainStr = domain ? (char *)__WBCFStringCopyUTF8Characters(domain) : NULL;

  status = SecKeychainAddInternetPassword(keychain,
                                          (UInt32)strlen(serverStr), serverStr,
                                          domainStr ? (UInt32)strlen(domainStr) : 0, domainStr ? : NULL,
                                          (UInt32)strlen(accountStr), accountStr,
                                          pathStr ? (UInt32)strlen(pathStr) : 0, pathStr ? : NULL,
                                          port, protocol, authenticationType,
                                          (UInt32)strlen(passwordStr), passwordStr,
                                          itemRef);

bail:
    if (serverStr) free(serverStr);
  if (accountStr) free(accountStr);
  if (passwordStr) free(passwordStr);
  if (pathStr) free(pathStr);
  if (domainStr) free(domainStr);
  return status;
}

//Call SecKeychainItemModifyAttributesAndData to change the password for // an item already in the keychain:
OSStatus WBKeychainModifyGenericPassword(SecKeychainItemRef itemRef, CFStringRef service, CFStringRef account, CFStringRef password) {
  OSStatus status;
  char *serviceStr = service ? (char *)__WBCFStringCopyUTF8Characters(service) : NULL;
  char *accountStr = account ? (char *)__WBCFStringCopyUTF8Characters(account) : NULL;
  char *passwordStr = password ? (char *)__WBCFStringCopyUTF8Characters(password) : NULL;

  UInt32 idx = 0;
  SecKeychainAttribute attrs[2];
  if (serviceStr) {
    attrs[idx].data = serviceStr;
    attrs[idx].tag = kSecServiceItemAttr;
    attrs[idx].length = (UInt32)strlen(serviceStr);
    idx++;
  }

  if (accountStr) {
    attrs[idx].data = accountStr;
    attrs[idx].tag = kSecAccountItemAttr;
    attrs[idx].length = (UInt32)strlen(accountStr);
    idx++;
  }
  const SecKeychainAttributeList attributes = { idx, attrs };

  status = SecKeychainItemModifyAttributesAndData(itemRef,
                                                  idx > 0 ? &attributes : NULL,
                                                  passwordStr ? (UInt32)strlen(passwordStr) : 0, passwordStr ? : NULL);

  if (serviceStr) free(serviceStr);
  if (accountStr) free(accountStr);
  if (passwordStr) free(passwordStr);
  return status;
}

//Call SecKeychainItemModifyAttributesAndData to change the password for // an item already in the keychain:
OSStatus WBKeychainModifyInternetPassword(SecKeychainItemRef itemRef, CFStringRef server, CFStringRef domain, CFStringRef account,
                                          CFStringRef path, UInt16 port, SecProtocolType protocol, SecAuthenticationType authenticationType,
                                          CFStringRef password) {
  OSStatus status;
  char *pathStr = path ? (char *)__WBCFStringCopyUTF8Characters(path) : NULL;
  char *domainStr = domain ? (char *)__WBCFStringCopyUTF8Characters(domain) : NULL;
  char *serverStr = server ? (char *)__WBCFStringCopyUTF8Characters(server) : NULL;
  char *accountStr = account ? (char *)__WBCFStringCopyUTF8Characters(account) : NULL;
  char *passwordStr = password ? (char *)__WBCFStringCopyUTF8Characters(password) : NULL;

  UInt32 idx = 0;
  SecKeychainAttribute attrs[7];
  /* Port */
  if (port) {
    attrs[idx].data = &port;
    attrs[idx].length = (UInt32)sizeof(port);
    attrs[idx].tag = kSecPortItemAttr;
    idx++;
  }
  /* Path */
  if (pathStr) {
    attrs[idx].data = pathStr;
    attrs[idx].tag = kSecPathItemAttr;
    attrs[idx].length = (UInt32)strlen(pathStr);
    idx++;
  }
  /* Domain */
  if (domainStr) {
    attrs[idx].data = domainStr;
    attrs[idx].length = (UInt32)strlen(domainStr);
    attrs[idx].tag = kSecSecurityDomainItemAttr;
    idx++;
  }
  /* Server */
  if (serverStr) {
    attrs[idx].data = serverStr;
    attrs[idx].tag = kSecServerItemAttr;
    attrs[idx].length = (UInt32)strlen(serverStr);
    idx++;
  }
  /* Account */
  if (accountStr) {
    attrs[idx].data = accountStr;
    attrs[idx].tag = kSecAccountItemAttr;
    attrs[idx].length = (UInt32)strlen(accountStr);
    idx++;
  }
  /* Protocol */
  if (protocol) {
    attrs[idx].data = &protocol;
    attrs[idx].length = (UInt32)sizeof(protocol);
    attrs[idx].tag = kSecProtocolItemAttr;
    idx++;
  }
  /* Authentication Type */
  if (authenticationType) {
    attrs[idx].data = &authenticationType;
    attrs[idx].length = (UInt32)sizeof(authenticationType);
    attrs[idx].tag = kSecAuthenticationTypeItemAttr;
    idx++;
  }
  const SecKeychainAttributeList attributes = { idx, attrs };

  status = SecKeychainItemModifyAttributesAndData(itemRef,
                                                  idx > 0 ? &attributes : NULL,
                                                  passwordStr ? (UInt32)strlen(passwordStr) : 0, passwordStr ? : NULL);

  if (pathStr) free(domainStr);
  if (domainStr) free(accountStr);
  if (serverStr) free(serverStr);
  if (accountStr) free(accountStr);
  if (passwordStr) free(passwordStr);
  return status;
}
