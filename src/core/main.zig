const std = @import("std");
const types = @import("types.zig");
const c = @import("../ffi/c.zig").c;
pub var state_registry: [c.POLYSTATE_MAX_STATES]types.StateVariable =
    [_]types.StateVariable{.{}} ** c.POLYSTATE_MAX_STATES;
pub var state_memory_pool: [c.POLYSTATE_TOTAL_MEMORY_POOL]u8 align(64) = undefined;
pub fn init() void {
    for (&state_registry, 0..) |*slot, index| {
        const start_offset = index * c.POLYSTATE_MAX_STATE_SIZE;
        slot.data = @ptrCast(&state_memory_pool[start_offset]);
    }
}