/*
 *  WBXMLWriter.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBXMLWriter.h)

#include <libxml/xmlwriter.h>

#define wb_writer (xmlTextWriterPtr)wb_pwriter
#define XSTR(str) (const xmlChar *)(str)

static
int _WBNSDataXMLOutputWrite(void *context, const char * buffer, int len) {
  NSMutableData *data = (NSMutableData *)context;
  [data appendBytes:buffer length:len];
  return len;
}

static
int _WBNSDataXMLOutputClose(void *context) {
  [(id)context release];
  return 0;
}

static
xmlOutputBufferPtr _WBXMLCreateNSDataOutputBuffer(NSMutableData *data, xmlCharEncodingHandlerPtr encoder) {
  NSCParameterAssert(data);
  xmlOutputBufferPtr output = xmlOutputBufferCreateIO(_WBNSDataXMLOutputWrite, _WBNSDataXMLOutputClose, data, encoder);
  if (output) [data retain]; // closing the buffer will release the data.
  return output;
}

@implementation WBXMLWriter

- (id)initWithURL:(NSURL *)anURL {
  return [self initWithNativeWriter:xmlNewTextWriterFilename([[anURL absoluteString] UTF8String], 0)];
}

- (id)initWithData:(NSMutableData *)data {
  xmlOutputBufferPtr output = _WBXMLCreateNSDataOutputBuffer(data, NULL);
  if (output) {
    self = [self initWithNativeWriter:xmlNewTextWriter(output)];
    if (!self)
      xmlOutputBufferClose(output);
  } else {
    [self release];
    self = nil;
  }
  return self;
}

- (id)initWithNativeWriter:(void *)aWriter {
  if (!aWriter) {
    [self release];
    self = nil;
  } else if (self = [super init]) {
    wb_pwriter = aWriter;
  }
  return self;
}

- (void)dealloc {
  [self close];
  wb_dealloc();
}

#pragma mark -
- (NSInteger)flush {
  if (wb_pwriter)
    return xmlTextWriterFlush(wb_writer);
  return 0;
}
- (void)close {
  if (wb_pwriter) {
    xmlTextWriterFlush(wb_writer);
    xmlFreeTextWriter(wb_writer);
    wb_pwriter = NULL;
  }
}

- (BOOL)indent {
  return wb_indent;
}
- (void)setIndent:(BOOL)indent {
  if (0 == xmlTextWriterSetIndent(wb_writer, indent ? 1 : 0))
    wb_indent = indent;
}
- (void)setIndentString:(NSString *)str {
  xmlTextWriterSetIndentString(wb_writer, XSTR([str UTF8String]));
}

#pragma mark Document
- (NSInteger)startDocument:(NSString *)version encoding:(NSString *)encoding standalone:(NSString *)standalone {
  return xmlTextWriterStartDocument(wb_writer, [version UTF8String], [encoding UTF8String], [standalone UTF8String]);
}

- (NSInteger)endDocument {
  return xmlTextWriterEndDocument(wb_writer);
}

- (NSInteger)writeProcessingInstruction:(NSString *)target content:(NSString *)content {
  return xmlTextWriterWritePI(wb_writer, XSTR([target UTF8String]), XSTR([content UTF8String]));
}

- (NSInteger)writeDocType:(NSString *)name publicID:(NSString *)pub systemID:(NSString *)sys subset:(NSString *)subset {
  return xmlTextWriterWriteDTD(wb_writer, XSTR([name UTF8String]), XSTR([pub UTF8String]), XSTR([sys UTF8String]), XSTR([subset UTF8String]));
}

#pragma mark Comment
- (NSInteger)startComment {
  return xmlTextWriterStartComment(wb_writer);
}
- (NSInteger)endComment {
  return xmlTextWriterEndComment(wb_writer);
}
- (NSInteger)writeCommentString:(NSString *)aComment {
  return [self writeCommentUTF8String:[aComment UTF8String]];
}
- (NSInteger)writeCommentUTF8String:(const char *)aComment {
  return xmlTextWriterWriteComment(wb_writer, XSTR(aComment));
}
- (NSInteger)writeCommentWithFormat:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatComment(wb_writer, format, args);
  va_end(args);
  return count;
}

#pragma mark Element
- (NSInteger)startElement:(NSString *)name {
  return xmlTextWriterStartElement(wb_writer, XSTR([name UTF8String]));
}

- (NSInteger)startElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI {
  return xmlTextWriterStartElementNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]));
}
- (NSInteger)endElement {
  return xmlTextWriterEndElement(wb_writer);
}
- (NSInteger)endElement:(BOOL)full {
  if (full) return xmlTextWriterFullEndElement(wb_writer);
  return xmlTextWriterEndElement(wb_writer);
}

- (NSInteger)writeElement:(NSString *)name string:(NSString *)content {
  return [self writeElement:name UTF8String:[content UTF8String]];
}
- (NSInteger)writeElement:(NSString *)name UTF8String:(const char *)content {
  if (!content) return [self writeEmptyElement:name];
  return xmlTextWriterWriteElement(wb_writer, XSTR([name UTF8String]), XSTR(content));
}
- (NSInteger)writeEmptyElement:(NSString *)name {
  NSInteger cnt = [self startElement:name];
  if (cnt >= 0) {
    NSInteger cnt2 = [self endElement];
    cnt = cnt2 >= 0 ? cnt + cnt2 : -1;
  }
  return cnt;
}

- (NSInteger)writeElement:(NSString *)name format:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatElement(wb_writer, XSTR([name UTF8String]), format, args);
  va_end(args);
  return count;
}

- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI string:(NSString *)content {
  return [self writeElement:name prefix:prefix namespace:namespaceURI UTF8String:[content UTF8String]];
}
- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI UTF8String:(const char *)content {
  if (!content) return [self writeEmptyElement:name prefix:prefix namespace:namespaceURI];
  return xmlTextWriterWriteElementNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]), XSTR(content));
}

- (NSInteger)writeElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI format:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatElementNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]), format, args);
  va_end(args);
  return count;
}

- (NSInteger)writeEmptyElement:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI {
  NSInteger cnt = [self startElement:name prefix:prefix namespace:namespaceURI];
  if (cnt >= 0) {
    NSInteger cnt2 = [self endElement];
    cnt = cnt2 >= 0 ? cnt + cnt2 : -1;
  }
  return cnt;
}

#pragma mark Attribute
- (NSInteger)startAttribute:(NSString *)name {
  return xmlTextWriterStartAttribute(wb_writer, XSTR([name UTF8String]));
}
- (NSInteger)startAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI {
  return xmlTextWriterStartAttributeNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]));
}
- (NSInteger)endAtttribute {
  return xmlTextWriterEndAttribute(wb_writer);
}

- (NSInteger)writeAttribute:(NSString *)name string:(NSString *)content {
  return [self writeAttribute:name UTF8String:[content UTF8String]];
}
- (NSInteger)writeAttribute:(NSString *)name UTF8String:(const char *)content {
  return xmlTextWriterWriteAttribute(wb_writer, XSTR([name UTF8String]), XSTR(content));
}

- (NSInteger)writeAttribute:(NSString *)name format:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatAttribute(wb_writer, XSTR([name UTF8String]), format, args);
  va_end(args);
  return count;
}

- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI string:(NSString *)content {
  return [self writeAttribute:name prefix:prefix namespace:namespaceURI UTF8String:[content UTF8String]];
}
- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI UTF8String:(const char *)content {
  return xmlTextWriterWriteAttributeNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]), XSTR(content));
}

- (NSInteger)writeAttribute:(NSString *)name prefix:(NSString *)prefix namespace:(NSString *)namespaceURI format:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatAttributeNS(wb_writer, XSTR([prefix UTF8String]), XSTR([name UTF8String]), XSTR([namespaceURI UTF8String]), format, args);
  va_end(args);
  return count;
}

#pragma mark String
- (NSInteger)writeString:(NSString *)aString {
  return [self writeUTF8String:[aString UTF8String]];
}
- (NSInteger)writeUTF8String:(const char *)str {
  return xmlTextWriterWriteString(wb_writer, XSTR(str));
}
- (NSInteger)writeFormat:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatString(wb_writer, format, args);
  va_end(args);
  return count;
}

#pragma mark CDATA
- (NSInteger)startCDATA {
  return xmlTextWriterStartCDATA(wb_writer);
}
- (NSInteger)endCDATA {
  return xmlTextWriterEndCDATA(wb_writer);
}

- (NSInteger)writeCDATA:(NSString *)cdata {
  return [self writeUTF8CDATA:[cdata UTF8String]];
}
- (NSInteger)writeUTF8CDATA:(const char *)cdata {
  return xmlTextWriterWriteCDATA(wb_writer, XSTR(cdata));
}
- (NSInteger)writeCDATAFormat:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatCDATA(wb_writer, format, args);
  va_end(args);
  return count;
}

#pragma mark Data
- (NSInteger)writeBase64Data:(NSData *)aData {
  return xmlTextWriterWriteBase64(wb_writer, [aData bytes], 0, [aData length]);
}
- (NSInteger)writeBase64Data:(NSData *)aData range:(NSRange)aRange {
  /* should check range */
  return xmlTextWriterWriteBase64(wb_writer, [aData bytes], aRange.location, aRange.length);
}
- (NSInteger)writeBase64Bytes:(const void *)bytes range:(NSRange)aRange {
  return xmlTextWriterWriteBase64(wb_writer, bytes, aRange.location, aRange.length);
}

- (NSInteger)writeBinHexData:(NSData *)aData {
  return xmlTextWriterWriteBinHex(wb_writer, [aData bytes], 0, [aData length]);
}
- (NSInteger)writeBinHexData:(NSData *)aData range:(NSRange)aRange {
  /* should check range */
  return xmlTextWriterWriteBinHex(wb_writer, [aData bytes], aRange.location, aRange.length);
}
- (NSInteger)writeBinHexBytes:(const void *)bytes range:(NSRange)aRange {
  return xmlTextWriterWriteBinHex(wb_writer, bytes, aRange.location, aRange.length);
}

#pragma mark Raw
- (NSInteger)writeRawString:(NSString *)aString {
  return [self writeRawUTF8String:[aString UTF8String]];
}
- (NSInteger)writeRawUTF8String:(const char *)str {
  return xmlTextWriterWriteRaw(wb_writer, XSTR(str));
}
- (NSInteger)writeRawFormat:(const char *)format, ... {
  va_list args;
  va_start(args, format);
  NSInteger count = xmlTextWriterWriteVFormatRaw(wb_writer, format, args);
  va_end(args);
  return count;
}
- (NSInteger)writeRawUTF8String:(const char *)bytes range:(NSRange)range {
  return xmlTextWriterWriteRawLen(wb_writer, XSTR(bytes + range.location), range.length);
}


@end
