#ifndef POLYSTATE_H
#define POLYSTATE_H
#include <poly_state/types/buffer.h>
#include <poly_state/types/results.h>
#include <poly_state/types/macros.h>
static const uint32_t POLYSTATE_MAX_STATES = 256;
static const uint32_t POLYSTATE_MAX_STATE_SIZE = 1024 * 1024;
static const uint64_t POLYSTATE_TOTAL_MEMORY_POOL = 
    (uint64_t)POLYSTATE_MAX_STATES * (uint64_t)POLYSTATE_MAX_STATE_SIZE;
typedef struct poly_state_api {
    POLYSTATE_RESULT (CALL* create) (uint64_t id, uint32_t size);
    POLYSTATE_RESULT (CALL* write)  (uint64_t id, BUFFER_WRITE* out_buffer);
    POLYSTATE_RESULT (CALL* read)   (uint64_t id, BUFFER_READ*  out_buffer);
    POLYSTATE_RESULT (CALL* erase)  (uint64_t id);
} poly_state_api;
extern const poly_state_api PolyState;
void CALL poly_state_init(void);
#endif