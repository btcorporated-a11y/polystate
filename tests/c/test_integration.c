#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <poly_state/api.h>
int main() {
    printf("Starting PolyState C Integration Test...\n");
    poly_state_init();
    uint64_t state_id = 12345;
    uint32_t state_size = 256;
    POLYSTATE_RESULT res = PolyState.create(state_id, state_size);
    assert(res == POLYSTATE_OK && "Failed to create state");
    printf("State created successfully.\n");
    BUFFER_WRITE write_buf;
    res = PolyState.write(state_id, &write_buf);
    assert(res == POLYSTATE_OK && "Failed to acquire write buffer");
    assert(write_buf.size == state_size && "Write buffer size mismatch");
    const char* test_msg = "Hello from C Integration Test!";
    strncpy((char*)write_buf.data, test_msg, write_buf.size - 1);
    write_buf.data[write_buf.size - 1] = '\0';
    printf("Data written to state successfully.\n");
    BUFFER_READ read_buf;
    res = PolyState.read(state_id, &read_buf);
    assert(res == POLYSTATE_OK && "Failed to acquire read buffer");
    assert(read_buf.size == state_size && "Read buffer size mismatch");
    assert(strcmp((const char*)read_buf.data, test_msg) == 0 && "Data mismatch on read");
    printf("Data read and verified successfully.\n");
    res = PolyState.erase(state_id);
    assert(res == POLYSTATE_OK && "Failed to erase state");
    res = PolyState.read(state_id, &read_buf);
    assert(res == POLYSTATE_ERROR && "Reading an erased state should fail");
    printf("State erased successfully.\n");
    printf("C Integration Test Passed!\n");
    return 0;
}