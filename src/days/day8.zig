const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day8.txt";

const Vec = struct {
    x: i32,
    y: i32,

    pub fn add(self: *const Vec, other: *const Vec) Vec {
        return Vec{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: *const Vec, other: *const Vec) Vec {
        return Vec{ .x = self.x - other.x, .y = self.y - other.y };
    }
};

const Input = struct {
    antennas: AutoHashMap(u8, []Vec),
    size: Vec,

    pub fn contains(self: *const Input, position: *const Vec) bool {
        return position.x >= 0 and position.x <= self.size.x and position.y >= 0 and position.y <= self.size.y;
    }
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
    var antinodes = AutoHashMap(Vec, void).init(allocator);
    defer antinodes.deinit();

    var iter = input.antennas.iterator();

    while (iter.next()) |entry| {
        const positions = entry.value_ptr;

        for (0..positions.len) |outer_loop| {
            for (outer_loop..positions.len) |inner_loop| {
                if (outer_loop == inner_loop) {
                    continue;
                }

                const pos0 = positions.*[outer_loop];
                const pos1 = positions.*[inner_loop];
                const distance = pos1.sub(&pos0);

                const r0 = pos0.sub(&distance);
                const r1 = pos1.add(&distance);

                if (input.contains(&r0)) {
                    try antinodes.put(r0, undefined);
                }

                if (input.contains(&r1)) {
                    try antinodes.put(r1, undefined);
                }
            }
        }
    }

    try stdout.print("Part one: {d}\n", .{antinodes.count()});
}

fn partTwo(input: Input) !void {
    var antinodes = AutoHashMap(Vec, void).init(allocator);
    defer antinodes.deinit();

    var iter = input.antennas.iterator();

    while (iter.next()) |entry| {
        const positions = entry.value_ptr;

        for (0..positions.len) |outer_loop| {
            for (outer_loop..positions.len) |inner_loop| {
                if (outer_loop == inner_loop) {
                    continue;
                }

                const pos0 = positions.*[outer_loop];
                const pos1 = positions.*[inner_loop];

                try antinodes.put(pos0, undefined);
                try antinodes.put(pos1, undefined);

                const distance = pos1.sub(&pos0);

                var r0 = pos0.sub(&distance);

                while (input.contains(&r0)) {
                    try antinodes.put(r0, undefined);
                    r0 = r0.sub(&distance);
                }

                var r1 = pos1.add(&distance);

                while (input.contains(&r1)) {
                    try antinodes.put(r1, undefined);
                    r1 = r1.add(&distance);
                }
            }
        }
    }

    try stdout.print("Part two: {d}\n", .{antinodes.count()});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var collect = AutoHashMap(u8, ArrayList(Vec)).init(allocator);
    defer collect.deinit();

    var position = Vec{ .x = 0, .y = 0 };

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        position.x = 0;

        for (line) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                if (collect.contains(c)) {
                    try collect.getPtr(c).?.append(position);
                } else {
                    var list = ArrayList(Vec).init(allocator);
                    try list.append(position);

                    try collect.put(c, list);
                }
            }

            position.x += 1;
        }

        position.y += 1;
    }

    position.x -= 1;
    position.y -= 1;

    var collect_iter = collect.keyIterator();
    var antennas = AutoHashMap(u8, []Vec).init(allocator);

    while (collect_iter.next()) |key| {
        const list = collect.getPtr(key.*).?;
        try antennas.put(key.*, try list.toOwnedSlice());
    }

    return .{ .antennas = antennas, .size = position };
}
