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

const Parsed = struct {
    temp: i32,
    nl_idx: usize,
};

fn parseTempAt(buffer: []u8, semi: usize) Parsed {
    var cursor = semi + 1;
    const negative: i32 = parse_sign: {
        if (buffer[cursor] == '-') {
            cursor += 1;
            break :parse_sign -1;
        } else {
            break :parse_sign 1;
        }
    };
    if (buffer[cursor + 1] == '.') {
        return Parsed{
            .temp = negative * (((@as(i32, buffer[cursor]) - '0') * 10) + (@as(i32, buffer[cursor + 2]) - '0')),
            .nl_idx = cursor + 3,
        };
    } else {
        return Parsed{
            .temp = negative * (((@as(i32, buffer[cursor]) - '0') * 100) + ((@as(i32, buffer[cursor + 1]) - '0') * 10) + (@as(i32, buffer[cursor + 3]) - '0')),
            .nl_idx = cursor + 4,
        };
    }
}

fn entryLessThan(_: void, a: Entry, b: Entry) bool {
    return std.mem.lessThan(u8, a.key, b.key);
}

fn findSemicolon(buffer: []u8, cursor: usize) usize {
    if (cursor + 128 > buffer.len) {
        for (cursor..buffer.len) |i| {
            if (buffer[i] == ';') {
                return i;
            }
        }
    }
    const array_ptr: *const [128]u8 = @ptrCast(buffer[cursor..].ptr);
    const v_data: @Vector(128, u8) = array_ptr.*;
    const v_semi: @Vector(128, u8) = @splat(';');
    const semi_matches = v_data == v_semi;
    const semi_mask: u128 = @bitCast(semi_matches);
    return cursor + @ctz(semi_mask);
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
        const semi = findSemicolon(buffer, cursor);
        const city = buffer[cursor..semi];
        const parsed = parseTempAt(buffer, semi);
        cursor = parsed.nl_idx + 1;
        const result = try data.getOrPut(city);
        if (result.found_existing) {
            result.value_ptr.*.min = @min(result.value_ptr.*.min, parsed.temp);
            result.value_ptr.*.max = @max(result.value_ptr.*.max, parsed.temp);
            result.value_ptr.*.total += parsed.temp;
            result.value_ptr.*.count += 1;
        } else {
            result.key_ptr.* = city;
            result.value_ptr.* = Data{ .min = parsed.temp, .max = parsed.temp, .total = parsed.temp, .count = 1 };
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
