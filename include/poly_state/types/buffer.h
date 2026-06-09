#ifndef POLYSTATE_TYPES_BUFFER_H
#define POLYSTATE_TYPES_BUFFER_H
#include <stdint.h>
typedef struct BUFFER_READ{
    const uint8_t*  data;
    uint32_t  size;
}BUFFER_READ;
typedef struct BUFFER_WRITE{
    uint8_t*  data;
    uint32_t  size;
}BUFFER_WRITE;
#endif