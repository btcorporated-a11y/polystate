const std = @import("std");
const root = @import("weon-sdk");
const c = root.c;
test "Security: Initialization and Basic Constraints" {
    root.poly_state_init();
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.create.?(1, 0));
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.create.?(2, c.POLYSTATE_MAX_STATE_SIZE + 1));
}
test "Security: State limits and duplicates" {
    root.poly_state_init();
    try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.create.?(100, 1024));
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.create.?(100, 1024));
    var r_buf: c.BUFFER_READ = undefined;
    var w_buf: c.BUFFER_WRITE = undefined;
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.read.?(999, &r_buf));
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.write.?(999, &w_buf));
    try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.erase.?(100));
}
test "Security: Max States Limit" {
    root.poly_state_init();
    var count: u64 = 0;
    while (count < c.POLYSTATE_MAX_STATES) : (count += 1) {
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.create.?(2000 + count, 10));
    }
    try std.testing.expectEqual(c.POLYSTATE_ERROR, root.PolyState.create.?(2000 + count, 10));
    count = 0;
    while (count < c.POLYSTATE_MAX_STATES) : (count += 1) {
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.erase.?(2000 + count));
    }
}
fn threadWorker(start_id: u64, iterations: u32) !void {
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        const id = start_id + i;
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.create.?(id, 128));
        var w_buf: c.BUFFER_WRITE = undefined;
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.write.?(id, &w_buf));
        w_buf.data[0] = @truncate(id);
        var r_buf: c.BUFFER_READ = undefined;
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.read.?(id, &r_buf));
        try std.testing.expectEqual(@as(u8, @truncate(id)), r_buf.data[0]);
        try std.testing.expectEqual(c.POLYSTATE_OK, root.PolyState.erase.?(id));
    }
}
test "Multithreading: Concurrent state operations" {
    root.poly_state_init();
    const thread_count = 4;
    const iterations_per_thread = 50; 
    var threads: [thread_count]std.Thread = undefined;
    for (&threads, 0..) |*t, i| {
        const start_id = 10000 + @as(u64, i) * 1000;
        t.* = try std.Thread.spawn(.{}, threadWorker, .{ start_id, iterations_per_thread });
    }
    for (&threads) |*t| {
        t.join();
    }
}
test "Speed/Performance: Operations overhead" {
    root.poly_state_init();
    const count = 10000;
    var timer = try std.time.Timer.start();
    var i: u64 = 0;
    while (i < count) : (i += 1) {
        const id = 50000 + i;
        _ = root.PolyState.create.?(id, 64);
        var w_buf: c.BUFFER_WRITE = undefined;
        _ = root.PolyState.write.?(id, &w_buf);
        var r_buf: c.BUFFER_READ = undefined;
        _ = root.PolyState.read.?(id, &r_buf);
        _ = root.PolyState.erase.?(id);
    }
    const elapsed_ns = timer.read();
    const ops_per_sec = (@as(u128, count) * std.time.ns_per_s) / elapsed_ns;
    std.debug.print("\n[Performance] {} fully cycled states in {} ns (~{} ops/sec)\n", .{count, elapsed_ns, ops_per_sec});
}