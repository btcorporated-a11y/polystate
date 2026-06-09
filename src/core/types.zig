const std = @import("std");
pub const SlotState = enum(u8) {
    empty = 0,
    creating = 1,
    active = 2,
    erasing = 3,
};
pub const StateVariable = struct {
    id: u64 = 0,
    size: u32 = 0,
    status: std.atomic.Value(SlotState) = std.atomic.Value(SlotState).init(.empty),
    data: ?[*]u8 = null,
    pub fn tryAcquire(self: *StateVariable) bool {
        return self.status.cmpxchgStrong(.empty, .creating, .acquire, .monotonic) == null;
    }
    pub fn markActive(self: *StateVariable) void {
        self.status.store(.active, .release);
    }
};