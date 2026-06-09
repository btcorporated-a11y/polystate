const std = @import("std");
pub const c = @import("ffi/c.zig").c;
const core = @import("core/main.zig");
const func = @import("core/func.zig");
pub export fn poly_state_init() callconv(.c) void {
    core.init();
}
pub export const PolyState = c.poly_state_api{
    .create = func.create,
    .write = func.write,
    .read = func.read,
    .erase = func.erase,
};