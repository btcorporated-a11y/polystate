#ifndef POLYSTATE_TYPES_MACROS_H
#define POLYSTATE_TYPES_MACROS_H
#if defined(_WIN32)
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT __attribute__((visibility("default")))
#endif
#if defined(_WIN32)
    #define CALL __cdecl
#else
    #define CALL
#endif
#endif