const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day11.txt";

const Stone = struct {
    value: u64,

    pub fn blink(self: Stone) struct { Stone, ?Stone } {
        return switch (self.value) {
            0 => {
                return .{ .{ .value = 1 }, null };
            },
            else => {
                var i: u64 = 1;

                while (self.value % std.math.pow(u64, 10, i) != self.value) {
                    i += 1;
                }

                if (i % 2 == 0) {
                    const left_value = self.value / std.math.pow(u64, 10, i / 2);
                    const right_value = self.value % std.math.pow(u64, 10, i / 2);

                    return .{ .{ .value = left_value }, .{ .value = right_value } };
                } else {
                    return .{ .{ .value = self.value * 2024 }, null };
                }
            },
        };
    }
};

const Cache = AutoHashMap(struct { Stone, u64 }, u64);

const Input = struct {
    stones: []Stone,

    pub fn blink(self: Input, times: u64) ![]Stone {
        var stones = try allocator.alloc(Stone, self.stones.len);
        std.mem.copyForwards(Stone, stones, self.stones);

        for (0..times) |_| {
            var new_stones = ArrayList(Stone).init(allocator);

            for (stones) |stone| {
                const blink_stone = stone.blink();

                try new_stones.append(blink_stone[0]);

                if (blink_stone[1] != null) {
                    try new_stones.append(blink_stone[1].?);
                }
            }

            allocator.free(stones);
            stones = try new_stones.toOwnedSlice();
        }

        return stones;
    }

    pub fn blink_caching(self: Input, times: u64) !u64 {
        var cache = Cache.init(allocator);
        defer cache.deinit();

        var total_count: u64 = 0;

        for (self.stones) |stone| {
            total_count += try recursive_blink(stone, times, &cache);
        }

        return total_count;
    }

    fn recursive_blink(stone: Stone, times: u64, cache: *Cache) !u64 {
        if (cache.contains(.{ stone, times })) {
            return cache.get(.{ stone, times }).?;
        }

        const new_stones = stone.blink();

        if (times == 1) {
            if (new_stones[1] == null) {
                return 1;
            } else {
                return 2;
            }
        }

        var result = try recursive_blink(new_stones[0], times - 1, cache);

        if (new_stones[1] != null) {
            result += try recursive_blink(new_stones[1].?, times - 1, cache);
        }

        try cache.put(.{ stone, times }, result);

        return result;
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
    const result_stones = try input.blink(25);

    try stdout.print("Part one: {d}\n", .{result_stones.len});
}

fn partTwo(input: Input) !void {
    const total_stones = try input.blink_caching(75);

    try stdout.print("Part two: {d}\n", .{total_stones});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    const length = try in_stream.readAll(&buf);

    var iter = std.mem.tokenizeScalar(u8, buf[0 .. length - 1], ' ');
    var stone_list = ArrayList(Stone).init(allocator);

    while (iter.next()) |number| {
        const value = std.fmt.parseInt(u64, number, 10) catch {
            break;
        };
        try stone_list.append(.{ .value = value });
    }

    return Input{ .stones = try stone_list.toOwnedSlice() };
}
