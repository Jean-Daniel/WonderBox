/*
 *  WBMediaFunctions.c
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import WBHEADER(WBMediaFunctions.h)

static const char sBlank[48] = {
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t',
'\t', '\t', '\t', '\t', '\t', '\t', '\t', '\t'
};

void WBMediaPrintAtomContainer(QTAtomContainer atoms) {
  WBMediaPrintAtoms(atoms, kParentAtomIsContainer, 0);
}

void WBMediaPrintAtoms(QTAtomContainer atoms, QTAtom parentAtom, CFIndex level) {
  if (level > 32) return;
  
  fprintf(stderr, "%.*s", (int)level, sBlank);
  QTAtomType type;
  QTGetAtomTypeAndID(atoms, parentAtom, &type, NULL);
  type = OSSwapHostToBigInt32(type);
  fprintf(stderr, "'%4.4s': ", (char *)&type);
  
  fprintf(stderr, "\n");
  
  QTAtom atom = 0;
  OSStatus err = QTNextChildAnyType(atoms, parentAtom, atom, &atom);
  while (noErr == err && atom) {
    WBMediaPrintAtoms(atoms, atom, level + 1);
    err = QTNextChildAnyType(atoms, parentAtom, atom, &atom);
  }
}

CFStringRef WBMediaCopyStringForPixelFormat(OSType format) {
  switch (format) {
    default: 
      return UTCreateStringForOSType(format) ? : CFSTR("????");
    case 0: return CFSTR("Undefined format !");
    case kCVPixelFormatType_1Monochrome: return CFSTR("Monochrome");
    case kCVPixelFormatType_2Indexed:    return CFSTR("2 bits indexed");
    case kCVPixelFormatType_4Indexed:    return CFSTR("4 bits indexed");
    case kCVPixelFormatType_8Indexed:    return CFSTR("8 bits indexed");
      
    case kCVPixelFormatType_1IndexedGray_WhiteIsZero: return CFSTR("1 bit indexed gray, white is zero");
    case kCVPixelFormatType_2IndexedGray_WhiteIsZero: return CFSTR("2 bits indexed gray, white is zero");
    case kCVPixelFormatType_4IndexedGray_WhiteIsZero: return CFSTR("4 bits indexed gray, white is zero");
    case kCVPixelFormatType_8IndexedGray_WhiteIsZero: return CFSTR("8 bits indexed gray, white is zero");
      
    case kCVPixelFormatType_16BE555:  return CFSTR("16 bits BE RGB 555");
    case kCVPixelFormatType_16LE555:  return CFSTR("16 bits LE RGB 555");
    case kCVPixelFormatType_16LE5551: return CFSTR("16 bits LE RGB 5551");
    case kCVPixelFormatType_16BE565:  return CFSTR("16 bits BE RGB 565");
    case kCVPixelFormatType_16LE565:  return CFSTR("16 bits LE RGB 565");
      
    case kCVPixelFormatType_24RGB:  return CFSTR("24 bits RGB");
    case kCVPixelFormatType_24BGR:  return CFSTR("24 bits BGR");
    case kCVPixelFormatType_32ARGB: return CFSTR("32 bits ARGB");
    case kCVPixelFormatType_32BGRA: return CFSTR("32 bits BGRA");
    case kCVPixelFormatType_32ABGR: return CFSTR("32 bits ABGR");
    case kCVPixelFormatType_32RGBA: return CFSTR("32 bits RGBA");
    case kCVPixelFormatType_64ARGB: return CFSTR("64 bits ARGB, 16-bit big-endian samples");
    case kCVPixelFormatType_48RGB:  return CFSTR("48 bits RGB, 16-bit big-endian samples");
      
    case kCVPixelFormatType_32AlphaGray: return CFSTR("32 bits AlphaGray, 16-bit big-endian samples, black is zero");
    case kCVPixelFormatType_16Gray:     return CFSTR("16 bits Grayscale, 16-bit big-endian samples, black is zero");

    case kCVPixelFormatType_422YpCbCr8:       return CFSTR("Y'CbCr 8-bits 4:2:2, ordered Cb Y'0 Cr Y'1 ('2vuy')");
    case kCVPixelFormatType_4444YpCbCrA8:     return CFSTR("Y'CbCrA 8-bits 4:4:4:4, ordered Cb Y' Cr A");
    case kCVPixelFormatType_4444YpCbCrA8R:    return CFSTR("Y'CbCrA 8-bits 4:4:4:4, ordered A Y' Cb Cr");
    case kCVPixelFormatType_444YpCbCr8:       return CFSTR("Y'CbCr 8-bits 4:4:4");
    case kCVPixelFormatType_422YpCbCr16:      return CFSTR("Y'CbCr 10,12,14,16-bit 4:2:2");
    case kCVPixelFormatType_422YpCbCr10:      return CFSTR("Y'CbCr 10-bits 4:2:2");
    case kCVPixelFormatType_444YpCbCr10:      return CFSTR("Y'CbCr 10-bits 4:4:4");
    case kCVPixelFormatType_420YpCbCr8Planar: return CFSTR("Planar Y'CbCr 8-bits 4:2:0.");
      
    case kYUVSPixelFormat:    return CFSTR("YUV 4:2:2 byte ordering 16-unsigned = 'YUY2'");
    case kYUVUPixelFormat:    return CFSTR("YUV 4:2:2 byte ordering 16-signed");
    case kYVU9PixelFormat:    return CFSTR("YVU9 Planar 9");
    case kYUV411PixelFormat:  return CFSTR("YUV 4:1:1 Interleaved 16");
    case kYVYU422PixelFormat: return CFSTR("YVYU 4:2:2 byte ordering 16");
    case kUYVY422PixelFormat: return CFSTR("UYVY 4:2:2 byte ordering 16");
    case kYUV211PixelFormat:  return CFSTR("YUV 2:1:1 Packed 8");
  }
}

NSString *WBMediaStringForPixelFormat(OSType format) {
  return WBCFAutorelease(WBMediaCopyStringForPixelFormat(format));
}

QTTime WBCVBufferGetMovieTime(CVBufferRef buffer) {
  QTTime qttime = QTIndefiniteTime;
  if (buffer) {
    CFDictionaryRef timestamp = CVBufferGetAttachment(buffer, kCVBufferMovieTimeKey, NULL);
    if (timestamp) {
      CFNumberRef scale = CFDictionaryGetValue(timestamp, kCVBufferTimeScaleKey);
      CFNumberRef value = CFDictionaryGetValue(timestamp, kCVBufferTimeValueKey);
      if (scale && value) {
        qttime = QTZeroTime;
        CFNumberGetValue(scale, kCFNumberLongType, &qttime.timeScale);
        CFNumberGetValue(value, kCFNumberLongLongType, &qttime.timeValue);
      }
    }
  }
  return qttime;
}
