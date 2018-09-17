/*
 *  WBTemplate.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */
/*!
    @header WBTemplate
    @abstract   (description)
    @discussion (description)
*/

#import <WonderBox/WBTreeNode.h>

/*!
    @class
    @abstract    (brief description)
    @discussion  (comprehensive description)
*/
WB_OBJC_EXPORT
@interface WBTemplate : WBTreeNode {
@protected
  NSString *wb_name;
  NSMutableArray *wb_blocks;
  NSMutableArray *wb_contents;
  NSMutableDictionary *wb_vars;
  struct _wb_tplFlags {
    unsigned int removeBlockLine:1;
    unsigned int inBlock:1;
    unsigned int:6;
  } wb_tplFlags;
}

- (instancetype)initWithContentsOfFile:(NSString *)aFile encoding:(NSStringEncoding)encoding;
- (instancetype)initWithContentsOfURL:(NSURL *)anURL encoding:(NSStringEncoding)encoding;

@property NSStringEncoding encoding;

/*!
    @method     reset
    @abstract   Clear all variables and blocks.
*/
- (void)reset;

- (BOOL)isBlock;
- (void)dumpBlock;
- (NSString *)name;
- (__kindof WBTemplate *)blockWithName:(NSString *)aName;

- (BOOL)containsKey:(NSString *)key;

- (NSString *)variableForKey:(NSString *)aKey;
- (void)setVariable:(NSString *)aValue forKey:(NSString *)aKey;

@property BOOL removeBlockLine;

- (NSString *)stringRepresentation;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag andReset:(BOOL)reset;
- (BOOL)writeToURL:(NSURL *)Url atomically:(BOOL)flag andReset:(BOOL)reset;

- (BOOL)load;
- (BOOL)loadFile:(NSString *)aFile;

- (NSArray *)allKeys;
- (NSArray *)allBlocks;
- (NSDictionary *)structure;

@end
