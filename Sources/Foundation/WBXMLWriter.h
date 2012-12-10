/*
 *  WBXMLWriter.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>

WB_OBJC_EXPORT
@interface WBXMLWriter : NSObject {
@private
  bool wb_indent;
  void *wb_pwriter;
}

- (id)initWithURL:(NSURL *)anURL;
- (id)initWithData:(NSMutableData *)data;

- (id)initWithNativeWriter:(void *)aWriter;

#pragma mark -
- (NSInteger)flush;
- (void)close;

- (BOOL)indent;
- (void)setIndent:(BOOL)indent;
- (void)setIndentString:(NSString *)str;

#pragma mark Document
- (NSInteger)startDocument:(NSString *)version encoding:(NSString *)encoding standalone:(NSString *)standalone;
- (NSInteger)endDocument;

- (NSInteger)writeProcessingInstruction:(NSString *)target content:(NSString *)content;
- (NSInteger)writeDocType:(NSString *)name publicID:(NSString *)pub systemID:(NSString *)sys subset:(NSString *)subset;

#pragma mark Comment
- (NSInteger)startComment;
- (NSInteger)endComment;

- (NSInteger)writeCommentString:(NSString *)aComment;
- (NSInteger)writeCommentUTF8String:(const char *)aComment;
- (NSInteger)writeCommentWithFormat:(const char *)format, ...;

#pragma mark Element
- (NSInteger)startElement:(NSString *)name;
- (NSInteger)startElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI;
/* if full is YES, add a close tag even if the element is empty */
- (NSInteger)endElement:(BOOL)full;
- (NSInteger)endElement;

- (NSInteger)writeEmptyElement:(NSString *)name;
- (NSInteger)writeElement:(NSString *)name string:(NSString *)content;
- (NSInteger)writeElement:(NSString *)name UTF8String:(const char *)content;
- (NSInteger)writeElement:(NSString *)name format:(const char *)format, ...;

- (NSInteger)writeEmptyElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI;
- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI string:(NSString *)content;
- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI UTF8String:(const char *)content;
- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI format:(const char *)format, ...;

#pragma mark Attribute
- (NSInteger)startAttribute:(NSString *)name;
- (NSInteger)startAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI;
- (NSInteger)endAtttribute;

- (NSInteger)writeAttribute:(NSString *)name string:(NSString *)content;
- (NSInteger)writeAttribute:(NSString *)name UTF8String:(const char *)content;
- (NSInteger)writeAttribute:(NSString *)name format:(const char *)format, ...;

- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI string:(NSString *)content;
- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI UTF8String:(const char *)content;
- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI format:(const char *)format, ...;

#pragma mark String
- (NSInteger)writeString:(NSString *)aString;
- (NSInteger)writeUTF8String:(const char *)str;
- (NSInteger)writeFormat:(const char *)format, ...;

#pragma mark CDATA
- (NSInteger)startCDATA;
- (NSInteger)endCDATA;

- (NSInteger)writeCDATA:(NSString *)cdata;
- (NSInteger)writeUTF8CDATA:(const char *)cdata;
- (NSInteger)writeCDATAFormat:(const char *)format, ...;

#pragma mark Data
- (NSInteger)writeBase64Data:(NSData *)aData;
- (NSInteger)writeBase64Data:(NSData *)aData range:(NSRange)aRange;
- (NSInteger)writeBase64Bytes:(const void *)bytes range:(NSRange)aRange;

- (NSInteger)writeBinHexData:(NSData *)aData;
- (NSInteger)writeBinHexData:(NSData *)aData range:(NSRange)aRange;
- (NSInteger)writeBinHexBytes:(const void *)bytes range:(NSRange)aRange;

#pragma mark Raw
- (NSInteger)writeRawString:(NSString *)aString;
- (NSInteger)writeRawUTF8String:(const char *)str;
- (NSInteger)writeRawFormat:(const char *)format, ...;
- (NSInteger)writeRawUTF8String:(const char *)bytes range:(NSRange)range;


@end
