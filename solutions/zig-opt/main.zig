const std = @import("std");

const Data = struct {
    min: i32,
    max: i32,
    total: i32,
    count: i32,
};

fn parse_temp(temp: []const u8) !i32 {
    var buf: [4]u8 = undefined;
    var len: usize = 0;
    for (temp) |c| {
        if (c != '.') {
            buf[len] = c;
            len += 1;
        }
    }
    return std.fmt.parseInt(i32, buf[0..len], 10);
}

fn ascLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
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
    const file = try std.Io.Dir.cwd().openFile(io, "../../data/measurements.txt", .{ .mode = .read_only });
    defer file.close(io);
    const stat = try file.stat(io);
    const buffer = try std.posix.mmap(
        null,
        stat.size,
        .{ .READ = true },
        .{ .TYPE = .SHARED },
        file.handle,
        0,
    );
    defer std.posix.munmap(buffer);
    var cursor: usize = 0;
    while (cursor < buffer.len) {
        const city_index = std.mem.findScalarPos(u8, buffer, cursor, ';') orelse break;
        const city = buffer[cursor..city_index];
        const temp_index = std.mem.findScalarPos(u8, buffer, city_index + 1, '\n') orelse break;
        const temp_str = buffer[city_index + 1 .. temp_index];
        const temp = try parse_temp(temp_str);
        cursor = temp_index + 1;
        const result = try data.getOrPut(city);
        if (result.found_existing) {
            result.value_ptr.*.min = @min(result.value_ptr.*.min, temp);
            result.value_ptr.*.max = @max(result.value_ptr.*.max, temp);
            result.value_ptr.*.total += temp;
            result.value_ptr.*.count += 1;
        } else {
            result.key_ptr.* = city;
            result.value_ptr.* = Data{ .min = temp, .max = temp, .total = temp, .count = 1 };
        }
    }
    var backing_buffer: [1024][]const u8 = undefined;
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
    for (keys) |key| {
        const value = data.get(key).?;
        try stdout.print("{s}\t{d}\t{d}\t{d}\t{d}\n", .{
            key,
            value.min,
            value.max,
            value.total,
            value.count,
        });
    }
    try writer.flush();
}
