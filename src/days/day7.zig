const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day7.txt";

const Line = struct {
    result: u64,
    numbers: []u64,
};

const Input = struct {
    lines: []Line,
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
    var calibration_sum: u64 = 0;

    for (input.lines) |line| {
        if (isValidAddMul(line)) {
            calibration_sum += line.result;
        }
    }

    try stdout.print("Part one: {d}\n", .{calibration_sum});
}

fn partTwo(input: Input) !void {
    var calibration_sum: u64 = 0;

    for (input.lines) |line| {
        if (isValidAddMulCat(line)) {
            calibration_sum += line.result;
        }
    }

    try stdout.print("Part two: {d}\n", .{calibration_sum});
}

fn isValidAddMul(line: Line) bool {
    return addMul(line.result, line.numbers[0], line.numbers[1..]);
}

fn addMul(target: u64, current: u64, remaining: []u64) bool {
    const add = current + remaining[0];
    const mul = current * remaining[0];

    if (remaining.len == 1) {
        return add == target or mul == target;
    }

    return addMul(target, add, remaining[1..]) or addMul(target, mul, remaining[1..]);
}

fn isValidAddMulCat(line: Line) bool {
    return addMulCat(line.result, line.numbers[0], line.numbers[1..]);
}

fn addMulCat(target: u64, current: u64, remaining: []u64) bool {
    const add = current + remaining[0];
    const mul = current * remaining[0];
    const cat = catNumbers(current, remaining[0]);

    if (remaining.len == 1) {
        return add == target or mul == target or cat == target;
    }

    return addMulCat(target, add, remaining[1..]) or addMulCat(target, mul, remaining[1..]) or addMulCat(target, cat, remaining[1..]);
}

fn catNumbers(left: u64, right: u64) u64 {
    var multiplicator: u64 = 1;

    while (right % multiplicator != right) {
        multiplicator *= 10;
    }

    return left * multiplicator + right;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines = ArrayList(Line).init(allocator);

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split = std.mem.splitScalar(u8, line, ':');

        const result = try std.fmt.parseInt(u64, split.next().?, 10);
        const numbers_part = split.next().?;

        var numbers_iter = std.mem.splitScalar(u8, numbers_part, ' ');
        var numbers_list = ArrayList(u64).init(allocator);

        _ = numbers_iter.next();

        while (numbers_iter.next()) |number_string| {
            const number = try std.fmt.parseInt(u64, number_string, 10);
            try numbers_list.append(number);
        }

        try lines.append(Line{ .result = result, .numbers = try numbers_list.toOwnedSlice() });
    }

    return .{ .lines = try lines.toOwnedSlice() };
}
