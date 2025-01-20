const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const allocator = std.heap.page_allocator;
const stdout = std.io.getStdOut().writer();

const input_path = "inputs/day13.txt";

const Vec = struct {
    x: u64,
    y: u64,

    pub fn add(self: Vec, other: Vec) Vec {
        return Vec{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn scalarMul(self: Vec, scalar: u64) Vec {
        return Vec{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn distance(self: Vec) f64 {
        const x_sq = self.x * self.x;
        const y_sq = self.y * self.y;
        const total = x_sq + y_sq;

        return std.math.sqrt(@as(f64, @floatFromInt(total)));
    }
};

const Machine = struct {
    a: Vec,
    b: Vec,
    prize: Vec,

    pub fn lgs(self: *const Machine) ?u64 {
        const d: i64 = @as(i64, @intCast(self.a.x * self.b.y)) - @as(i64, @intCast(self.a.y * self.b.x));
        const d_x: i64 = @as(i64, @intCast(self.prize.x * self.b.y)) - @as(i64, @intCast(self.prize.y * self.b.x));
        const d_y: i64 = @as(i64, @intCast(self.a.x * self.prize.y)) - @as(i64, @intCast(self.a.y * self.prize.x));

        if (d == 0) {
            return null;
        }

        const a = @divTrunc(d_x, d);
        const b = @divTrunc(d_y, d);

        if (a < 0 or b < 0) {
            return null;
        }

        const result = self.a.scalarMul(@intCast(a)).add(self.b.scalarMul(@intCast(b)));

        if (result.x == self.prize.x and result.y == self.prize.y) {
            return @as(u64, @intCast(a)) * 3 + @as(u64, @intCast(b));
        }

        return null;
    }

    pub fn cheapestSolution(self: *const Machine) ?u64 {
        if (self.a.distance() > 3.0 * self.b.distance()) {
            return self.highALowB();
        } else {
            return self.highBLowA();
        }
    }

    fn highBLowA(self: *const Machine) ?u64 {
        var a_count: u64 = 0;
        var b_count: u64 = 100;

        while (true) {
            const current = self.a.scalarMul(a_count).add(self.b.scalarMul(b_count));

            if (current.x == self.prize.x and current.y == self.prize.y) {
                return a_count * 3 + b_count;
            }

            if (current.x > self.prize.x or current.y > self.prize.y) {
                if (b_count == 0) {
                    return null;
                }

                b_count -= 1;
            }

            if (current.x < self.prize.x or current.y < self.prize.y) {
                if (a_count == 100) {
                    return null;
                }

                a_count += 1;
            }
        }

        return null;
    }

    fn highALowB(self: *const Machine) ?u64 {
        var a_count: u64 = 100;
        var b_count: u64 = 0;

        while (true) {
            const current = self.a.scalarMul(a_count).add(self.b.scalarMul(b_count));

            if (current.x == self.prize.x and current.y == self.prize.y) {
                return a_count * 3 + b_count;
            }

            if (current.x > self.prize.x or current.y > self.prize.y) {
                if (a_count == 0) {
                    return null;
                }

                a_count -= 1;
            }

            if (current.x < self.prize.x or current.y < self.prize.y) {
                if (b_count == 100) {
                    return null;
                }

                b_count += 1;
            }
        }

        return null;
    }
};

const Input = struct {
    machines: []Machine,

    pub fn allCheapestSolutionsSum(self: *const Input) u64 {
        var sum: u64 = 0;

        for (self.machines) |machine| {
            if (machine.cheapestSolution()) |cost| {
                sum += cost;
            }
        }

        return sum;
    }

    pub fn allCheapestSolutionsAdjustedSum(self: *const Input) u64 {
        const adjustment = 10000000000000;

        var sum: u64 = 0;

        for (self.machines) |machine| {
            const adjusted = Machine{
                .a = machine.a,
                .b = machine.b,
                .prize = Vec{
                    .x = machine.prize.x + adjustment,
                    .y = machine.prize.y + adjustment,
                },
            };

            if (adjusted.lgs()) |cost| {
                sum += cost;
            }
        }

        return sum;
    }
};

pub fn main() !void {
    const input = readInput() catch |err| {
        try stdout.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    defer allocator.free(input.machines);

    try partOne(input);
    try partTwo(input);
}

fn partOne(input: Input) !void {
    try stdout.print("Part one: {d}\n", .{input.allCheapestSolutionsSum()});
}

fn partTwo(input: Input) !void {
    try stdout.print("Part two: {d}\n", .{input.allCheapestSolutionsAdjustedSum()});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var machine: Machine = undefined;
    var machines = ArrayList(Machine).init(allocator);

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.startsWith(u8, line, "Button A")) {
            const x_index = std.mem.indexOf(u8, line, "X").?;
            const y_index = std.mem.indexOf(u8, line, "Y").?;
            const x = try std.fmt.parseInt(u32, line[x_index + 2 .. y_index - 2], 10);
            const y = try std.fmt.parseInt(u32, line[y_index + 2 ..], 10);

            machine.a = Vec{ .x = x, .y = y };
        } else if (std.mem.startsWith(u8, line, "Button B")) {
            const x_index = std.mem.indexOf(u8, line, "X").?;
            const y_index = std.mem.indexOf(u8, line, "Y").?;
            const x = try std.fmt.parseInt(u32, line[x_index + 2 .. y_index - 2], 10);
            const y = try std.fmt.parseInt(u32, line[y_index + 2 ..], 10);

            machine.b = Vec{ .x = x, .y = y };
        } else if (std.mem.startsWith(u8, line, "Prize")) {
            const x_index = std.mem.indexOf(u8, line, "X").?;
            const y_index = std.mem.indexOf(u8, line, "Y").?;
            const x = try std.fmt.parseInt(u32, line[x_index + 2 .. y_index - 2], 10);
            const y = try std.fmt.parseInt(u32, line[y_index + 2 ..], 10);

            machine.prize = Vec{ .x = x, .y = y };

            try machines.append(machine);
        }
    }

    return Input{ .machines = try machines.toOwnedSlice() };
}
