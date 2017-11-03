/*
 *  WBDefines.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2017 Jean-Daniel Dupas. All rights reserved.
 *
 *  File version: 116
 *  File Generated using “basegen --name=WonderBox --prefix=wb --objc --cxx”.
 */

#if !defined(WB_DEFINES_H__)
#define WB_DEFINES_H__ 1

// MARK: Clang Macros
#ifndef __has_builtin
#  define __has_builtin(x) __has_builtin_ ## x
#endif

#ifndef __has_attribute
#  define __has_attribute(x) __has_attribute_ ## x
#endif

#ifndef __has_feature
#  define __has_feature(x) __has_feature_ ## x
#endif

#ifndef __has_extension
#  define __has_extension(x) __has_feature(x)
#endif

#ifndef __has_include
#  define __has_include(x) 0
#endif

#ifndef __has_include_next
#  define __has_include_next(x) 0
#endif

#ifndef __has_warning
#  define __has_warning(x) 0
#endif

// MARK: Visibility
#if defined(_WIN32)
#  define WB_HIDDEN
#  if defined(WB_STATIC_LIBRARY)
#      define WB_VISIBLE
#  else
#    if defined(WONDERBOX_DLL_EXPORT)
#      define WB_VISIBLE __declspec(dllexport)
#    else
#      define WB_VISIBLE __declspec(dllimport)
#    endif
#  endif
#endif

#if !defined(WB_VISIBLE)
#  define WB_VISIBLE __attribute__((__visibility__("default")))
#endif

#if !defined(WB_HIDDEN)
#  define WB_HIDDEN __attribute__((__visibility__("hidden")))
#endif

#if !defined(WB_EXTERN)
#  if defined(__cplusplus)
#    define WB_EXTERN extern "C"
#  else
#    define WB_EXTERN extern
#  endif
#endif

/* WB_EXPORT WB_PRIVATE should be used on
 extern variables and functions declarations */
#if !defined(WB_EXPORT)
#  define WB_EXPORT WB_EXTERN WB_VISIBLE
#endif

#if !defined(WB_PRIVATE)
#  define WB_PRIVATE WB_EXTERN WB_HIDDEN
#endif

// MARK: Inline
#if defined(__cplusplus) && !defined(__inline__)
#  define __inline__ inline
#endif

#if !defined(WB_INLINE)
#  if !defined(__NO_INLINE__)
#    if defined(_MSC_VER)
#      define WB_INLINE __forceinline static
#    else
#      define WB_INLINE __inline__ __attribute__((__always_inline__)) static
#    endif
#  else
#    define WB_INLINE __inline__ static
#  endif /* No inline */
#endif

// MARK: Attributes
#if !defined(WB_NORETURN)
#  if defined(_MSC_VER)
#    define WB_NORETURN __declspec(noreturn)
#  else
#    define WB_NORETURN __attribute__((__noreturn__))
#  endif
#endif

#if !defined(WB_DEPRECATED)
#  if defined(_MSC_VER)
#    define WB_DEPRECATED(msg) __declspec(deprecated(msg))
#  elif defined(__clang__)
#    define WB_DEPRECATED(msg) __attribute__((__deprecated__(msg)))
#  else
#    define WB_DEPRECATED(msg) __attribute__((__deprecated__))
#  endif
#endif

#if !defined(WB_UNUSED)
#  if defined(_MSC_VER)
#    define WB_UNUSED
#  else
#    define WB_UNUSED __attribute__((__unused__))
#  endif
#endif

#if !defined(WB_REQUIRES_NIL_TERMINATION)
#  if defined(_MSC_VER)
#    define WB_REQUIRES_NIL_TERMINATION
#  elif defined(__APPLE_CC__) && (__APPLE_CC__ >= 5549)
#    define WB_REQUIRES_NIL_TERMINATION __attribute__((__sentinel__(0,1)))
#  else
#    define WB_REQUIRES_NIL_TERMINATION __attribute__((__sentinel__))
#  endif
#endif

#if !defined(WB_REQUIRED_ARGS)
#  if defined(_MSC_VER)
#    define WB_REQUIRED_ARGS(idx, ...)
#  else
#    define WB_REQUIRED_ARGS(idx, ...) __attribute__((__nonnull__(idx, ##__VA_ARGS__)))
#  endif
#endif

#if !defined(WB_FORMAT)
#  if defined(_MSC_VER)
#    define WB_FORMAT(fmtarg, firstvararg)
#  else
#    define WB_FORMAT(fmtarg, firstvararg) __attribute__((__format__ (__printf__, fmtarg, firstvararg)))
#  endif
#endif

#if !defined(WB_CF_FORMAT)
#  if defined(__clang__)
#    define WB_CF_FORMAT(i, j) __attribute__((__format__(__CFString__, i, j)))
#  else
#    define WB_CF_FORMAT(i, j)
#  endif
#endif

#if !defined(WB_NS_FORMAT)
#  if defined(__clang__)
#    define WB_NS_FORMAT(i, j) __attribute__((__format__(__NSString__, i, j)))
#  else
#    define WB_NS_FORMAT(i, j)
#  endif
#endif

//! Project version number for WonderBox.
WB_EXTERN double WonderBoxVersionNumber;

//! Project version string for WonderBox.
WB_EXTERN const unsigned char WonderBoxVersionString[];


#if defined(__cplusplus)

/* WB_CXX_EXPORT and WB_CXX_PRIVATE can be used
 to define C++ classes visibility. */
#if defined(__cplusplus)
#  if !defined(WB_CXX_PRIVATE)
#    define WB_CXX_PRIVATE WB_HIDDEN
#  endif

#  if !defined(WB_CXX_EXPORT)
#    define WB_CXX_EXPORT WB_VISIBLE
#  endif
#endif

// GCC 4.x C++11 support
#if defined(__GNUC__) && !defined(__clang__) && !defined(__gcc_features_defined)
#define __gcc_features_defined 1

#if defined(__GXX_RTTI)
#  define __has_feature_cxx_rtti 1
#endif

#if defined(__EXCEPTIONS)
#  define __has_feature_cxx_exceptions 1
#endif

#define SPX_GCC_VERSION (__GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__)

// GCC 4.3
#if SPX_GCC_VERSION >= 40300
#  define __has_feature_cxx_static_assert 1
#  define __has_feature_cxx_rvalue_references 1
#endif

// GCC 4.4
#if SPX_GCC_VERSION >= 40400
#  define __has_feature_cxx_auto_type 1
#  define __has_feature_cxx_deleted_functions 1
#  define __has_feature_cxx_defaulted_functions 1
#endif

// GCC 4.5
#if SPX_GCC_VERSION >= 40500
#  define __has_feature_cxx_alignof 1
#  define __has_feature_cxx_lambdas 1
#  define __has_feature_cxx_decltype 1
#  define __has_feature_cxx_explicit_conversions 1
#endif

// GCC 4.6
#if SPX_GCC_VERSION >= 40600
#  define __has_feature_cxx_nullptr 1
#  define __has_feature_cxx_noexcept 1
#  define __has_feature_cxx_constexpr 1
#  define __has_feature_cxx_range_for 1
#endif

// GCC 4.7
#if SPX_GCC_VERSION >= 40700
#  define __has_feature_cxx_override_control 1
#  define __has_feature_cxx_delegating_constructors 1
#endif

// GCC 4.8
#if SPX_GCC_VERSION >= 40800
#  define __has_feature_cxx_alignas 1
#  define __has_feature_cxx_inheriting_constructors 1
#endif

#undef SPX_GCC_VERSION

#endif

#if defined(_MSC_VER) && !defined(__msc_features_defined)
#define __msc_features_defined 1

#define __has_builtin___debugbreak 1

// VisualStudio 2010
#if _MSC_VER >= 1600
#  define __has_feature_cxx_nullptr 1
#  define __has_feature_cxx_auto_type 1
#  define __has_feature_cxx_static_assert 1
#  define __has_feature_cxx_trailing_return 1
#  define __has_feature_cxx_override_control 1
#  define __has_feature_cxx_rvalue_references 1
#  define __has_feature_cxx_local_type_template_args 1
#endif

// VisualStudio 2011
#if _MSC_VER >= 1700
#  define __has_feature_cxx_lambdas 1
#  define __has_feature_cxx_decltype 1
#  define __has_feature_cxx_range_for 1
#endif

#endif /* _MSC_VER */

// MARK: C++ 2011
#if __has_extension(cxx_override_control)
#  if !defined(_MSC_VER) || _MSC_VER >= 1700
#    define wb_final final
#  else
#    define wb_final sealed
#  endif
#  define wb_override override
#else
// not supported
#  define wb_final
#  define wb_override
#endif

#if __has_extension(cxx_nullptr)
#  undef NULL
#  define NULL nullptr
#else
// use the standard declaration
#endif

#if __has_extension(cxx_noexcept)
#  define wb_noexcept noexcept
#  define wb_noexcept_(arg) noexcept(arg)
#else
#  define wb_noexcept
#  define wb_noexcept_(arg)
#endif

#if __has_extension(cxx_constexpr)
#  define wb_constexpr constexpr
#else
#  define wb_constexpr
#endif

#if __has_extension(cxx_rvalue_references)
/* declaration for move, swap, forward, ... */
#  define wb_move(arg) std::move(arg)
#  define wb_forward(Ty, arg) std::forward<Ty>(arg)
#else
#  define wb_move(arg) arg
#  define wb_forward(Ty, arg) arg
#endif

#if __has_extension(cxx_deleted_functions)
#  define wb_deleted = delete
#else
#  define wb_deleted
#endif

#if __has_feature(cxx_attributes) && __has_warning("-Wimplicit-fallthrough")
#  define wb_fallthrough [[clang::fallthrough]]
#else
#  define wb_fallthrough do {} while (0)
#endif

// MARK: Other C++ macros

// A macro to disallow the copy constructor and operator= functions
// This should be used in the private: declarations for a class
#ifndef WB_DISALLOW_COPY_AND_ASSIGN
#  define WB_DISALLOW_COPY_AND_ASSIGN(TypeName) \
private: \
TypeName(const TypeName&) wb_deleted; \
void operator=(const TypeName&) wb_deleted
#endif

#ifndef WB_DISALLOW_MOVE
#  if __has_extension(cxx_rvalue_references)
#    define WB_DISALLOW_MOVE(TypeName) \
private: \
TypeName(TypeName&&) wb_deleted; \
void operator=(TypeName&&) wb_deleted
#  else
#    define WB_DISALLOW_MOVE(TypeName)
#  endif
#endif

#ifndef WB_DISALLOW_COPY_ASSIGN_MOVE
#  define WB_DISALLOW_COPY_ASSIGN_MOVE(TypeName) \
WB_DISALLOW_MOVE(TypeName);                  \
WB_DISALLOW_COPY_AND_ASSIGN(TypeName)
#endif

#endif /* __cplusplus */

#if defined(__OBJC__)

/* WB_OBJC_EXPORT and WB_OBJC_PRIVATE can be used
 to define ObjC classes visibility. */
#if !defined(WB_OBJC_PRIVATE)
#  if __LP64__
#    define WB_OBJC_PRIVATE WB_HIDDEN
#  else
#    define WB_OBJC_PRIVATE
#  endif /* 64 bits runtime */
#endif

#if !defined(WB_OBJC_EXPORT)
#  if __LP64__
#    define WB_OBJC_EXPORT WB_VISIBLE
#  else
#    define WB_OBJC_EXPORT
#  endif /* 64 bits runtime */
#endif

// MARK: Static Analyzer
#ifndef WB_UNUSED_IVAR
#  if __has_extension(attribute_objc_ivar_unused)
#    define WB_UNUSED_IVAR __attribute__((__unused__))
#  else
#    define WB_UNUSED_IVAR
#  endif
#endif

/* Method Family */
#ifndef NS_METHOD_FAMILY
/* supported families are: none, alloc, copy, init, mutableCopy, and new. */
#  if __has_attribute(ns_returns_autoreleased)
#    define NS_METHOD_FAMILY(family) __attribute__((objc_method_family(family)))
#  else
#    define NS_METHOD_FAMILY(arg)
#  endif
#endif

#endif /* ObjC */


#endif /* WB_DEFINES_H__ */
