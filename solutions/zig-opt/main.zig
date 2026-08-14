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

fn parseTemp(temp: []const u8) !i32 {
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

fn getSeperatorIndexes(buffer: []u8, cursor: usize) struct { usize, usize } {
    if (cursor + 128 > buffer.len) {
        var semi_idx: usize = cursor;
        var nl_idx: usize = cursor;
        var i = cursor;
        while (i < buffer.len) : (i += 1) {
            if (buffer[i] == ';') semi_idx = i;
            if (buffer[i] == '\n') {
                nl_idx = i;
                break;
            }
        }
        return .{ semi_idx, nl_idx };
    }
    const array_ptr: *const [128]u8 = @ptrCast(buffer[cursor..].ptr);
    const v_data: @Vector(128, u8) = array_ptr.*;
    const v_semi: @Vector(128, u8) = @splat(';');
    const v_nl: @Vector(128, u8) = @splat('\n');
    const semi_matches = v_data == v_semi;
    const nl_matches = v_data == v_nl;
    const semi_mask: u128 = @bitCast(semi_matches);
    const nl_mask: u128 = @bitCast(nl_matches);
    return .{
        cursor + @ctz(semi_mask),
        cursor + @ctz(nl_mask),
    };
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
        const indexes = getSeperatorIndexes(buffer, cursor);
        const city = buffer[cursor..indexes[0]];
        const temp = try parseTemp(buffer[indexes[0] + 1 .. indexes[1]]);
        cursor = indexes[1] + 1;
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
