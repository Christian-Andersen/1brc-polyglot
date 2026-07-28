const std = @import("std");

const Data = struct {
    min: i32,
    max: i32,
    total: i32,
    count: i32,
};

fn parse_temp(temp: []const u8) !i32 {
    var iter = std.mem.splitScalar(u8, temp, '.');
    const left = iter.next() orelse "";
    const right = iter.next() orelse "";
    var buf: [32]u8 = undefined;
    const new_str = try std.fmt.bufPrint(&buf, "{s}{s}", .{ left, right });
    return std.fmt.parseInt(i32, new_str, 10);
}

fn ascLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn roundTowardPositive(value: f64) f64 {
    return @floor(value + 0.5) / 10.0;
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator{
        .child_allocator = init.gpa,
        .state = .{},
    };
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    var data = std.StringHashMap(Data).init(arena_allocator);
    const io = init.io;
    const file = try std.Io.Dir.cwd().openFile(io, "../../data/measurements.txt", .{});
    defer file.close(io);
    var file_buffer: [256]u8 = undefined;
    var reader = file.reader(io, &file_buffer);
    while (try reader.interface.takeDelimiter('\n')) |line| {
        var iter = std.mem.splitScalar(u8, line, ';');
        const city = iter.next() orelse unreachable;
        const temp_str = iter.next() orelse unreachable;
        const temp = try parse_temp(temp_str);
        const result = try data.getOrPut(city);
        if (result.found_existing) {
            result.value_ptr.*.min = @min(result.value_ptr.*.min, temp);
            result.value_ptr.*.max = @max(result.value_ptr.*.max, temp);
            result.value_ptr.*.total += temp;
            result.value_ptr.*.count += 1;
        } else {
            result.key_ptr.* = try arena_allocator.dupe(u8, city);
            result.value_ptr.* = Data{ .min = temp, .max = temp, .total = temp, .count = 1 };
        }
    }
    var backing_buffer: [1000][]const u8 = undefined;
    var keys_list = std.ArrayListUnmanaged([]const u8).initBuffer(&backing_buffer);
    var iterator = data.keyIterator();
    while (iterator.next()) |key_ptr| {
        keys_list.appendAssumeCapacity(key_ptr.*);
    }
    const keys = keys_list.items;
    std.mem.sort([]const u8, keys, {}, ascLessThan);
    var buf: [40960]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const stdout = &writer.interface;
    try stdout.print("{{", .{});
    for (keys, 1..) |key, index| {
        const value = data.get(key).?;
        try stdout.print("{s}={d:.1}/{d:.1}/{d:.1}", .{
            key,
            roundTowardPositive(@as(f32, @floatFromInt(value.min))),
            roundTowardPositive(@as(f32, @floatFromInt(value.total)) / @as(f32, @floatFromInt(value.count))),
            roundTowardPositive(@as(f32, @floatFromInt(value.max))),
        });
        if (index < keys.len) {
            try stdout.print(", ", .{});
        }
    }
    try stdout.print("}}", .{});
    try writer.flush();
}
