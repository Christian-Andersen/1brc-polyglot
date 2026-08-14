const std = @import("std");

const Data = struct {
    min: i32,
    max: i32,
    total: i32,
    count: i32,
};

const Entry = struct {
    key: []const u8,
    value: Data,
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

fn entryLessThan(_: void, a: Entry, b: Entry) bool {
    return std.mem.lessThan(u8, a.key, b.key);
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
    var entries = std.ArrayListUnmanaged(Entry).empty;
    var iterator = data.iterator();
    while (iterator.next()) |kv| {
        try entries.append(arena_allocator, .{ .key = kv.key_ptr.*, .value = kv.value_ptr.* });
    }
    std.mem.sort(Entry, entries.items, {}, entryLessThan);
    var buf: [40960]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const stdout = &writer.interface;
    for (entries.items) |entry| {
        try stdout.print("{s}\t{d}\t{d}\t{d}\t{d}\n", .{
            entry.key,
            entry.value.min,
            entry.value.max,
            entry.value.total,
            entry.value.count,
        });
    }
    try writer.flush();
}
