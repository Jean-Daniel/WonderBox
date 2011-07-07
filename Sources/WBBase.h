/*
 *  WBBase.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#if !defined(__WONDERBOX_BASE_H)
#define __WONDERBOX_BASE_H 1

#if !defined(WB_VISIBLE)
  #define WB_VISIBLE __attribute__((visibility("default")))
#endif

#if !defined(WB_HIDDEN)
  #define WB_HIDDEN __attribute__((visibility("hidden")))
#endif

#if !defined(WB_EXTERN)
  #if defined(__cplusplus)
    #define WB_EXTERN extern "C"
  #else
    #define WB_EXTERN extern
  #endif
#endif

#if !defined(WB_PRIVATE)
  #define WB_PRIVATE WB_EXTERN WB_HIDDEN
#endif

#if !defined(WB_EXPORT)
  #if defined(WONDERBOX_FRAMEWORK)
    #define WB_EXPORT WB_EXTERN WB_VISIBLE
  #else
    #define WB_EXPORT WB_EXTERN WB_HIDDEN
  #endif
#endif

#if !defined(WB_OBJC_EXPORT)
  #if __LP64__
    #define WB_OBJC_PRIVATE WB_HIDDEN
    #if defined(WONDERBOX_FRAMEWORK)
      #define WB_OBJC_EXPORT WB_VISIBLE
    #else
      #define WB_OBJC_EXPORT WB_HIDDEN
    #endif
  #else
    #define WB_OBJC_EXPORT
    #define WB_OBJC_PRIVATE
  #endif /* Framework && 64 bits runtime */
#endif

#if !defined(WB_INLINE)
  #if !defined(__NO_INLINE__)
    #define WB_INLINE static __inline__ __attribute__((always_inline))
  #else
    #define WB_INLINE static __inline__
  #endif /* No inline */
#endif

/* Function Attributes */
#if !defined(WB_OBSOLETE)
  #if defined(_MSC_VER)
    #define WB_OBSOLETE(msg) __declspec(deprecated(msg))
  #elif defined(__clang__)
    #define WB_OBSOLETE(msg) __attribute__((deprecated(msg)))
  #else
    #define WB_OBSOLETE(msg) __attribute__((deprecated))
  #endif
#endif

#if !defined(WB_REQUIRES_NIL_TERMINATION)
  #if defined(_MSC_VER)
    #define WB_REQUIRES_NIL_TERMINATION
  #elif defined(__clang__) || (defined(__APPLE_CC__) && (__APPLE_CC__ >= 5549))
    #define WB_REQUIRES_NIL_TERMINATION __attribute__((sentinel(0,1)))
  #else /* GCC 4.0 */
    #define WB_REQUIRES_NIL_TERMINATION __attribute__((sentinel))
  #endif
#endif

#endif /* __WONDERBOX_BASE_H */
