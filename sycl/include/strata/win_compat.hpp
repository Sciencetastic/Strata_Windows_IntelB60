// sycl/include/strata/win_compat.hpp - force-included into every Strata translation unit of the SYCL port on Windows
// (sycl/CMakeLists.txt, /FI). The port was migrated on Linux, so names that the Windows SDK takes over as macros and
// the few POSIX calls without a Windows twin are dealt with here once, instead of in each migrated file.
#pragma once
#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <rpc.h>   // brings rpcndr.h, which defines `small` (char): pulled in first so later inclusions are no-ops
#include <direct.h>
#include <io.h>
#include <cstddef>
#include <cstdlib>
#include <cstring>
// rpcndr.h's `#define small char` collides with `const int64_t small` in generate.cpp. (IN / OUT are left alone:
// later SDK headers - combaseapi.h, rpcnsip.h - are written with them; the one kernel file that names a template
// parameter OUT undefines it itself, after its includes.)
#undef small

// POSIX memmem (glibc): first occurrence of needle in haystack, or nullptr
inline void* memmem(const void* haystack, size_t hlen, const void* needle, size_t nlen) {
    if (nlen == 0) return const_cast<void*>(haystack);
    if (hlen < nlen) return nullptr;
    const unsigned char* h = static_cast<const unsigned char*>(haystack);
    const unsigned char* n = static_cast<const unsigned char*>(needle);
    const unsigned char* end = h + (hlen - nlen) + 1;
    for (const unsigned char* p = h; p < end; ++p) {
        p = static_cast<const unsigned char*>(std::memchr(p, n[0], (size_t) (end - p)));
        if (p == nullptr) return nullptr;
        if (std::memcmp(p, n, nlen) == 0) return const_cast<unsigned char*>(p);
    }
    return nullptr;
}
// POSIX setenv / unsetenv over the CRT's _putenv_s
inline int setenv(const char* name, const char* value, int overwrite) {
    if (!overwrite && std::getenv(name) != nullptr) return 0;
    return ::_putenv_s(name, value) == 0 ? 0 : -1;
}
inline int unsetenv(const char* name) { return ::_putenv_s(name, "") == 0 ? 0 : -1; }
// POSIX mkdir(path, mode): Windows has no permission bits
inline int mkdir(const char* path, int /*mode*/) { return ::_mkdir(path); }
#endif
