/*
 *  WBBase64.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined (__WB_BASE64_H)
#define __WB_BASE64_H 1

__BEGIN_DECLS

// WBBase64
//
/// Helper for handling Base64 and WebSafeBase64 encodings
//
/// The webSafe methods use different character set and also the results aren't
/// always padded to a multiple of 4 characters.  This is done so the resulting
/// data can be used in urls and url query arguments without needing any
/// encoding.  You must use the webSafe* methods together, the data does not
/// interop with the RFC methods.

//
// Standard Base64 (RFC) handling
//

// encodeData:
//
/// Base64 encodes contents of the NSData object.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBBase64CreateDataByEncodingData(CFDataRef data);

// decodeData:
//
/// Base64 decodes contents of the NSData object.
//
/// Returns:
///   A new autoreleased NSData with the decoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBBase64CreateDataByDecodingData(CFDataRef data);

// encodeBytes:length:
//
/// Base64 encodes the data pointed at by |bytes|.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length);

// decodeBytes:length:
//
/// Base64 decodes the data pointed at by |bytes|.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length);

// stringByEncodingData:
//
/// Base64 encodes contents of the NSData object.
//
/// Returns:
///   A new autoreleased NSString with the encoded payload.  nil for any error.
//
WB_EXPORT
CFStringRef WBBase64CreateStringByEncodingData(CFDataRef data);

// stringByEncodingBytes:length:
//
/// Base64 encodes the data pointed at by |bytes|.
//
/// Returns:
///   A new autoreleased NSString with the encoded payload.  nil for any error.
//
WB_EXPORT
CFStringRef WBBase64CreateStringByEncodingBytes(const void *bytes, CFIndex length);

// decodeString:
//
/// Base64 decodes contents of the NSString.
//
/// Returns:
///   A new autoreleased NSData with the decoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBBase64CreateDataByDecodingString(CFStringRef string);

#pragma mark Web Safe
//
// Modified Base64 encoding so the results can go onto urls.
//
// The changes are in the characters generated and also allows the result to
// not be padded to a multiple of 4.
// Must use the matching call to encode/decode, won't interop with the
// RFC versions.
//

// webSafeEncodeData:padded:
//
/// WebSafe Base64 encodes contents of the NSData object.  If |padded| is YES
/// then padding characters are added so the result length is a multiple of 4.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBWSBase64CreateDataByEncodingData(CFDataRef data, bool padded);

// webSafeDecodeData:
//
/// WebSafe Base64 decodes contents of the NSData object.
//
/// Returns:
///   A new autoreleased NSData with the decoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBWSBase64CreateDataByDecodingData(CFDataRef data);

// webSafeEncodeBytes:length:padded:
//
/// WebSafe Base64 encodes the data pointed at by |bytes|.  If |padded| is YES
/// then padding characters are added so the result length is a multiple of 4.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBWSBase64CreateDataByEncodingBytes(const void *bytes, CFIndex length, bool padded);

// webSafeDecodeBytes:length:
//
/// WebSafe Base64 decodes the data pointed at by |bytes|.
//
/// Returns:
///   A new autoreleased NSData with the encoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBWSBase64CreateDataByDecodingBytes(const void *bytes, CFIndex length);

// stringByWebSafeEncodingData:padded:
//
/// WebSafe Base64 encodes contents of the NSData object.  If |padded| is YES
/// then padding characters are added so the result length is a multiple of 4.
//
/// Returns:
///   A new autoreleased NSString with the encoded payload.  nil for any error.
//
WB_EXPORT
CFStringRef WBWSBase64CreateStringByEncodingData(CFDataRef data, bool padded);

// stringByWebSafeEncodingBytes:length:padded:
//
/// WebSafe Base64 encodes the data pointed at by |bytes|.  If |padded| is YES
/// then padding characters are added so the result length is a multiple of 4.
//
/// Returns:
///   A new autoreleased NSString with the encoded payload.  nil for any error.
//
WB_EXPORT
CFStringRef WBWSBase64CreateStringByEncodingBytes(const void *bytes, CFIndex length, bool padded);

// webSafeDecodeString:
//
/// WebSafe Base64 decodes contents of the NSString.
//
/// Returns:
///   A new autoreleased NSData with the decoded payload.  nil for any error.
//
WB_EXPORT
CFDataRef WBWSBase64CreateDataByDecodingString(CFStringRef string);

__END_DECLS

#endif /* __WB_BASE64_H */
