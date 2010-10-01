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

#if !defined(WB_PRIVATE)
  #define WB_PRIVATE SC_PRIVATE
#endif

#if !defined(WB_EXPORT)
  #if defined(WONDERBOX_FRAMEWORK)
    #define WB_EXPORT SC_EXPORT
  #else
    #define WB_EXPORT SC_PRIVATE
  #endif
#endif

#if !defined(WB_INLINE)
  #define WB_INLINE SC_INLINE
#endif

#if !defined(WB_CLASS_EXPORT)
  #define WB_CLASS_PRIVATE SC_CLASS_PRIVATE
  #if defined(WONDERBOX_FRAMEWORK)
    #define WB_CLASS_EXPORT SC_CLASS_EXPORT
  #else
    #define WB_CLASS_EXPORT SC_CLASS_PRIVATE
  #endif
#endif

/* Function Attributes */
#if !defined(WB_OBSOLETE)
  #define WB_OBSOLETE SC_OBSOLETE
#endif

#if !defined(WB_REQUIRES_NIL_TERMINATION)
  #define WB_REQUIRES_NIL_TERMINATION SC_REQUIRES_NIL_TERMINATION
#endif

#endif /* __WONDERBOX_BASE_H */
