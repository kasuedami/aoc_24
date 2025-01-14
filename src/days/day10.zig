const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day10.txt";

const Vec = struct {
    x: i32,
    y: i32,
};

const Input = struct {
    map: [][]u8,
    starts: []Vec,
};

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const input = readInput() catch |err| {
        try stdout.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    try partOne(input);
    try partTwo(input);
}

fn partOne(input: Input) !void {
    var total_score: u32 = 0;

    for (input.starts) |start| {
        total_score += try startScore(input.map, start);
    }

    try stdout.print("Part one: {d}\n", .{total_score});
}

fn partTwo(input: Input) !void {
    var total_score: u32 = 0;

    for (input.starts) |start| {
        total_score += try startScoreDistinctRoutes(input.map, start);
    }

    try stdout.print("Part two: {d}\n", .{total_score});
}

fn startScore(maps: [][]u8, start: Vec) !u32 {
    if (maps[@intCast(start.y)][@intCast(start.x)] != 0) {
        return 0;
    }

    var result = try findPathRecursive(maps, start);
    defer result.deinit();

    return result.count();
}

fn startScoreDistinctRoutes(maps: [][]u8, start: Vec) !u32 {
    if (maps[@intCast(start.y)][@intCast(start.x)] != 0) {
        return 0;
    }

    var result = try findPathRecursiveDistinctRoutes(maps, start);
    defer result.deinit();

    return @intCast(result.items.len);
}

fn findPathRecursive(maps: [][]u8, position: Vec) !AutoHashMap(Vec, void) {
    const current_value = maps[@intCast(position.y)][@intCast(position.x)];
    var result = AutoHashMap(Vec, void).init(allocator);

    if (current_value == 9) {
        try result.put(position, undefined);
        return result;
    }

    if (position.x - 1 >= 0 and maps[@intCast(position.y)][@intCast(position.x - 1)] == current_value + 1) {
        const pos = Vec{ .x = position.x - 1, .y = position.y };
        var values = try findPathRecursive(maps, pos);

        var iter = values.keyIterator();

        while (iter.next()) |key| {
            try result.put(key.*, undefined);
        }

        values.deinit();
    }

    if (position.x + 1 < maps[@intCast(position.y)].len and maps[@intCast(position.y)][@intCast(position.x + 1)] == current_value + 1) {
        const pos = Vec{ .x = position.x + 1, .y = position.y };
        var values = try findPathRecursive(maps, pos);

        var iter = values.keyIterator();

        while (iter.next()) |key| {
            try result.put(key.*, undefined);
        }

        values.deinit();
    }

    if (position.y - 1 >= 0 and maps[@intCast(position.y - 1)][@intCast(position.x)] == current_value + 1) {
        const pos = Vec{ .x = position.x, .y = position.y - 1 };
        var values = try findPathRecursive(maps, pos);

        var iter = values.keyIterator();

        while (iter.next()) |key| {
            try result.put(key.*, undefined);
        }

        values.deinit();
    }

    if (position.y + 1 < maps.len and maps[@intCast(position.y + 1)][@intCast(position.x)] == current_value + 1) {
        const pos = Vec{ .x = position.x, .y = position.y + 1 };
        var values = try findPathRecursive(maps, pos);

        var iter = values.keyIterator();

        while (iter.next()) |key| {
            try result.put(key.*, undefined);
        }

        values.deinit();
    }

    return result;
}

fn findPathRecursiveDistinctRoutes(maps: [][]u8, position: Vec) !ArrayList(Vec) {
    const current_value = maps[@intCast(position.y)][@intCast(position.x)];
    var result = ArrayList(Vec).init(allocator);

    if (current_value == 9) {
        try result.append(position);
        return result;
    }

    if (position.x - 1 >= 0 and maps[@intCast(position.y)][@intCast(position.x - 1)] == current_value + 1) {
        const pos = Vec{ .x = position.x - 1, .y = position.y };
        var values = try findPathRecursiveDistinctRoutes(maps, pos);

        try result.appendSlice(values.items);
        values.deinit();
    }

    if (position.x + 1 < maps[@intCast(position.y)].len and maps[@intCast(position.y)][@intCast(position.x + 1)] == current_value + 1) {
        const pos = Vec{ .x = position.x + 1, .y = position.y };
        var values = try findPathRecursiveDistinctRoutes(maps, pos);

        try result.appendSlice(values.items);
        values.deinit();
    }

    if (position.y - 1 >= 0 and maps[@intCast(position.y - 1)][@intCast(position.x)] == current_value + 1) {
        const pos = Vec{ .x = position.x, .y = position.y - 1 };
        var values = try findPathRecursiveDistinctRoutes(maps, pos);

        try result.appendSlice(values.items);
        values.deinit();
    }

    if (position.y + 1 < maps.len and maps[@intCast(position.y + 1)][@intCast(position.x)] == current_value + 1) {
        const pos = Vec{ .x = position.x, .y = position.y + 1 };
        var values = try findPathRecursiveDistinctRoutes(maps, pos);

        try result.appendSlice(values.items);
        values.deinit();
    }

    return result;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = ArrayList(ArrayList(u8)).init(allocator);
    defer list.deinit();

    var starts = ArrayList(Vec).init(allocator);

    var position = Vec{ .x = 0, .y = 0 };

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var line_list = ArrayList(u8).init(allocator);
        position.x = 0;

        for (line) |c| {
            const height = c - 48;
            try line_list.append(height);

            if (height == 0) {
                try starts.append(position);
            }

            position.x += 1;
        }

        try list.append(line_list);

        position.y += 1;
    }

    var as_array = try allocator.alloc([]u8, list.items.len);

    for (0..as_array.len) |i| {
        as_array[i] = try list.items[i].toOwnedSlice();
    }

    return Input{ .map = as_array, .starts = try starts.toOwnedSlice() };
}
