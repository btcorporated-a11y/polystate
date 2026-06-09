const std = @import("std");
const c = @import("../ffi/c.zig").c;
const core = @import("main.zig");
pub fn create(id: u64, size: u32) callconv(.c) c.POLYSTATE_RESULT {
    if (size == 0 or size > c.POLYSTATE_MAX_STATE_SIZE) {
        return c.POLYSTATE_ERROR;
    }
    for (&core.state_registry) |*slot| {
        if (slot.status.load(.acquire) == .active and slot.id == id) {
            return c.POLYSTATE_ERROR;
        }
    }
    for (&core.state_registry) |*slot| {
        if (slot.tryAcquire()) {
            slot.id = id;
            slot.size = size;
            if (slot.data) |ptr| {
                const mem_slice = ptr[0..size];
                @memset(mem_slice, 0);
            }
            slot.markActive();
            return c.POLYSTATE_OK;
        }
    }
    return c.POLYSTATE_ERROR;
}
pub fn write(id: u64, out_buffer: [*c]c.BUFFER_WRITE) callconv(.c) c.POLYSTATE_RESULT {
    if (out_buffer == null) return c.POLYSTATE_ERROR;
    for (&core.state_registry) |*slot| {
        if (slot.status.load(.acquire) == .active and slot.id == id) {
            out_buffer.*.data = slot.data.?;
            out_buffer.*.size = slot.size;
            return c.POLYSTATE_OK;
        }
    }
    return c.POLYSTATE_ERROR;
}
pub fn read(id: u64, out_buffer: [*c]c.BUFFER_READ) callconv(.c) c.POLYSTATE_RESULT {
    if (out_buffer == null) return c.POLYSTATE_ERROR;
    for (&core.state_registry) |*slot| {
        if (slot.status.load(.acquire) == .active and slot.id == id) {
            out_buffer.*.data = @ptrCast(slot.data.?);
            out_buffer.*.size = slot.size;
            return c.POLYSTATE_OK;
        }
    }
    return c.POLYSTATE_ERROR;
}
pub fn erase(id: u64) callconv(.c) c.POLYSTATE_RESULT {
    for (&core.state_registry) |*slot| {
        if (slot.status.load(.acquire) == .active and slot.id == id) {
            if (slot.status.cmpxchgStrong(.active, .erasing, .acquire, .monotonic) == null) {
                slot.id = 0;
                slot.size = 0;
                slot.status.store(.empty, .release);
                return c.POLYSTATE_OK;
            }
        }
    }
    return c.POLYSTATE_ERROR;
}