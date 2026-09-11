const std = @import("std");

const HASH_MAP_SIZE = 16384; // TODO: adjust this down, which requires writing code for it to grow!
const MAX_CORES = 256;
var THREADS: [MAX_CORES]std.Thread = undefined;
var RESULTS: [MAX_CORES][HASH_MAP_SIZE]StationEntry = undefined;

const StationEntry = struct {
    name: []const u8 = undefined,
    min: i32 = 2000,
    max: i32 = -2000,
    total: i32 = 0,
    count: i32 = 0,
};

fn hashStation(name: []const u8) u32 {
    const len = name.len;
    var first_4: u32 = 0;
    if (len >= 4) {
        first_4 = std.mem.readInt(u32, name[0..4], .little);
    } else {
        for (name, 0..) |b, i| {
            first_4 |= @as(u32, b) << @intCast(i * 8);
        }
    }
    var last_4: u32 = 0;
    if (len >= 4) {
        last_4 = std.mem.readInt(u32, name[len - 4 .. len][0..4], .little);
    }
    var hash: u32 = first_4 ^ last_4 ^ @as(u32, @intCast(len));
    hash %= HASH_MAP_SIZE;
    return hash;
}

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

fn resultLessThan(_: void, a: Entry, b: Entry) bool {
    return std.mem.lessThan(u8, a.key, b.key);
}

fn findSemicolon(buffer: []u8, cursor: usize) usize {
    if (cursor + 16 > buffer.len) {
        return std.mem.indexOfScalarPos(u8, buffer, cursor, ';') orelse unreachable;
    }
    const semi: @Vector(16, u8) = @splat(';');
    const a_ptr: *const [16]u8 = @ptrCast(buffer[cursor..].ptr);
    const a: @Vector(16, u8) = a_ptr.*;
    const mask_a: u16 = @bitCast(a == semi);
    if (mask_a != 0) return cursor + @ctz(mask_a);
    const b_ptr: *const [16]u8 = @ptrCast(buffer[cursor..].ptr);
    const b: @Vector(16, u8) = b_ptr.*;
    const mask_b: u16 = @bitCast(b == semi);
    if (mask_b != 0) return cursor + @ctz(mask_b);
    return std.mem.indexOfScalarPos(u8, buffer, cursor + 32, ';') orelse unreachable;
}

fn getStationEntry(data: []StationEntry, city: []const u8) *StationEntry {
    const hash = hashStation(city);
    for (0..HASH_MAP_SIZE) |i| {
        const index = (hash + i) % HASH_MAP_SIZE;
        const result = &data[index];
        if (result.count == 0) {
            result.*.name = city;
            return result;
        }
        if (std.mem.eql(u8, city, result.name)) {
            return result;
        }
    }
    unreachable;
}

fn map(buffer: []u8, start_index: usize, end_index: usize, data: *[HASH_MAP_SIZE]StationEntry) void {
    var cursor = start_index;
    if ((cursor != 0) and (buffer[cursor - 1] != '\n')) {
        while (buffer[cursor] != '\n') {
            cursor += 1;
        }
        cursor += 1;
    }
    data.* = @splat(.{});
    while (cursor < end_index) {
        const semi = findSemicolon(buffer, cursor);
        const city = buffer[cursor..semi];
        const parsed = parseTempAt(buffer, semi);
        cursor = parsed.nl_idx + 1;
        const result = getStationEntry(data, city);
        result.min = @min(result.min, parsed.temp);
        result.max = @max(result.max, parsed.temp);
        result.total += parsed.temp;
        result.count += 1;
    }
}

pub fn main(init: std.process.Init) !void {
    // setup
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
    // threading
    const thread_count = @min(try std.Thread.getCpuCount(), MAX_CORES);
    const chunk_size = @divFloor(buffer.len, thread_count);
    for (0..thread_count) |i| {
        const start = i * chunk_size;
        const end = if (i == thread_count - 1) buffer.len else (i + 1) * chunk_size;
        THREADS[i] = try std.Thread.spawn(.{}, map, .{ buffer, start, end, &RESULTS[i] });
    }
    //collect
    for (0..thread_count) |i| {
        THREADS[i].join();
    }
    var data: [HASH_MAP_SIZE]StationEntry = @splat(.{});
    for (0..thread_count) |i| {
        for (RESULTS[i]) |datum| {
            if (datum.count == 0) continue;
            const result = getStationEntry(&data, datum.name);
            result.min = @min(result.min, datum.min);
            result.max = @max(result.max, datum.max);
            result.total += datum.total;
            result.count += datum.count;
        }
    }
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();
    var entries = std.ArrayListUnmanaged(Entry).empty;
    for (data) |result| {
        if (result.count != 0) {
            try entries.append(arena_allocator, .{
                .key = result.name,
                .value = .{
                    .min = result.min,
                    .max = result.max,
                    .total = result.total,
                    .count = result.count,
                },
            });
        }
    }
    std.mem.sort(Entry, entries.items, {}, resultLessThan);
    var buf: [65536]u8 = undefined;
    var writer = std.Io.File.stdout().writerStreaming(io, &buf);
    const stdout = &writer.interface;
    for (entries.items) |result| {
        try stdout.print("{s}\t{d}\t{d}\t{d}\t{d}\n", .{
            result.key,
            result.value.min,
            result.value.max,
            result.value.total,
            result.value.count,
        });
    }
    try writer.flush();
}
