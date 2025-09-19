#ifndef IOVM_API_H_
#define IOVM_API_H_

#if defined(WIN32)
#if defined(BUILDING_IOVM_DLL) || defined(BUILDING_IOVMALL_DLL)
#define IOVM_API __declspec(dllexport)
#elif defined(BUILDING_IOVM_STATIC) || defined(BUILDING_IOVMALL_STATIC)
#define IOVM_API
#else
#define IOVM_API __declspec(dllimport)
#endif

#else
#define IOVM_API
#endif

#endif
