const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const allocator = std.heap.page_allocator;
const stdout = std.io.getStdOut().writer();

const input_path = "inputs/day14.txt";

const Vec = struct {
    x: i64,
    y: i64,

    pub fn add(self: Vec, other: Vec) Vec {
        return Vec{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn scalarMul(self: Vec, scalar: i64) Vec {
        return Vec{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn doTouch(self: Vec, other: Vec) bool {
        return (self.x - 1 == other.x or self.x + 1 == other.x) and (self.y - 1 == other.y or self.y + 1 == other.y);
    }
};

const Bot = struct {
    position: Vec,
    velocity: Vec,

    pub fn moveSteps(self: *Bot, steps: u64, grid_size: Vec) void {
        const moved = self.position.add(self.velocity.scalarMul(@intCast(steps)));
        const clamped = Vec{ .x = @mod(moved.x, grid_size.x), .y = @mod(moved.y, grid_size.y) };

        self.position = clamped;
    }
};

const Input = struct {
    bots: []Bot,
    grid_size: Vec,

    pub fn clone(self: *const Input) !Input {
        return Input{
            .bots = try allocator.dupe(Bot, self.bots),
            .grid_size = self.grid_size,
        };
    }

    pub fn moveBots(self: *Input, steps: u64) void {
        for (self.bots) |*bot| {
            bot.moveSteps(steps, self.grid_size);
        }
    }

    pub fn botsPerQuadrant(self: *const Input) [4]u64 {
        var quadrant_counts = [_]u64{0} ** 4;

        const quadrant_border_x = @divExact(self.grid_size.x - 1, 2);
        const quadrant_border_y = @divExact(self.grid_size.y - 1, 2);

        for (self.bots) |bot| {
            if (bot.position.x == quadrant_border_x or bot.position.y == quadrant_border_y) {
                continue;
            }

            var quadrant: u8 = 0;

            if (bot.position.x > quadrant_border_x) {
                quadrant += 1;
            }

            if (bot.position.y < quadrant_border_y) {
                quadrant += 2;
            }

            quadrant_counts[quadrant] += 1;
        }

        return quadrant_counts;
    }

    pub fn findEasterEgg(self: *Input) u64 {
        var iteration: u64 = 0;

        while (self.touchingBots() < 300) {
            self.moveBots(1);
            iteration += 1;
        }

        return iteration;
    }

    pub fn touchingBots(self: *const Input) u64 {
        var count: u64 = 0;

        for (self.bots) |outer| {
            for (self.bots) |inner| {
                if (outer.position.doTouch(inner.position)) {
                    count += 1;
                }
            }
        }

        return count;
    }

    pub fn draw(self: *const Input) !void {
        var canvas = try allocator.alloc(u8, @intCast((self.grid_size.x + 1) * self.grid_size.y));
        defer allocator.free(canvas);
        @memset(canvas, '.');

        for (self.bots) |bot| {
            const index = (bot.position.x + (bot.position.y * (self.grid_size.x + 1)));
            canvas[@intCast(index)] = '0';
        }

        for (0..@intCast(self.grid_size.y)) |i| {
            const index = i * @as(usize, @intCast(self.grid_size.x + 1));
            std.debug.print("index: {d}\n", .{index});
            canvas[i * @as(usize, @intCast(self.grid_size.x + 1))] = '\n';
        }

        std.debug.print("{s}\n", .{canvas});
    }
};

pub fn main() !void {
    const input = readInput() catch |err| {
        try stdout.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    defer allocator.free(input.bots);

    try partOne(input);
    try partTwo(input);
}

fn partOne(input: Input) !void {
    var clone = try input.clone();
    defer allocator.free(clone.bots);

    clone.moveBots(100);
    const quadrant_counts = clone.botsPerQuadrant();
    const result = quadrant_counts[0] * quadrant_counts[1] * quadrant_counts[2] * quadrant_counts[3];

    try stdout.print("Part one: {d}\n", .{result});
}

fn partTwo(input: Input) !void {
    var clone = try input.clone();
    defer allocator.free(clone.bots);

    const result = clone.findEasterEgg();

    try stdout.print("Part two: {d}\n", .{result});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var bots = ArrayList(Bot).init(allocator);

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const position_index = std.mem.indexOf(u8, line, "p=").?;
        const velocity_index = std.mem.indexOf(u8, line, " v=").?;

        const position_comma_index = std.mem.indexOf(u8, line[position_index..velocity_index], ",").? + position_index;
        const velocity_comma_index = std.mem.indexOf(u8, line[velocity_index..], ",").? + velocity_index;

        const position_x = try std.fmt.parseInt(i64, line[position_index + 2 .. position_comma_index], 10);
        const position_y = try std.fmt.parseInt(i64, line[position_comma_index + 1 .. velocity_index], 10);

        const velocity_x = try std.fmt.parseInt(i64, line[velocity_index + 3 .. velocity_comma_index], 10);
        const velocity_y = try std.fmt.parseInt(i64, line[velocity_comma_index + 1 ..], 10);

        try bots.append(Bot{
            .position = Vec{
                .x = position_x,
                .y = position_y,
            },
            .velocity = Vec{
                .x = velocity_x,
                .y = velocity_y,
            },
        });
    }

    return Input{ .bots = try bots.toOwnedSlice(), .grid_size = Vec{ .x = 101, .y = 103 } };
}
