const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;
const eql = std.mem.eql;

const input_path = "inputs/day4.txt";
const Input = [][]u8;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const input = readInput() catch |err| {
        try stdout.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    try partOne(input);
    try partTwo(input);

    for (input) |line| {
        allocator.free(line);
    }

    allocator.free(input);
}

fn partOne(input: Input) !void {
    var xmas_count: u16 = 0;

    for (input, 0..) |line, i| {
        const vertical = try getVerticalLine(input, i);
        const up_left_down_right = try getUpLeftDownRightLine(input, i);
        const up_right_down_left = try getUpRightDownLeftLine(input, i);

        xmas_count += countLineXmas(line);
        xmas_count += countLineXmas(vertical);
        xmas_count += countLineXmas(up_left_down_right);
        xmas_count += countLineXmas(up_right_down_left);
    }

    try stdout.print("Part one: {d}\n", .{xmas_count});
}

fn partTwo(input: Input) !void {
    var xmas_count: u16 = 0;

    var kernel: [9]u8 = undefined;

    for (0..input.len - 2) |i| {
        for (0..input[i].len - 2) |j| {
            kernel[0] = input[i][j];
            kernel[1] = input[i][j + 1];
            kernel[2] = input[i][j + 2];

            kernel[3] = input[i + 1][j];
            kernel[4] = input[i + 1][j + 1];
            kernel[5] = input[i + 1][j + 2];

            kernel[6] = input[i + 2][j];
            kernel[7] = input[i + 2][j + 1];
            kernel[8] = input[i + 2][j + 2];

            if (isXmas(kernel)) {
                xmas_count += 1;
            }
        }
    }

    try stdout.print("Part two: {d}\n", .{xmas_count});
}

fn countLineXmas(line: []u8) u16 {
    var xmas_count: u16 = 0;

    for (0..line.len - 3) |i| {
        const chunk = line[i .. i + 4];

        if (eql(u8, chunk, "XMAS") or eql(u8, chunk, "SAMX")) {
            xmas_count += 1;
        }
    }

    return xmas_count;
}

fn getVerticalLine(input: Input, index: usize) ![]u8 {
    var line = try ArrayList(u8).initCapacity(allocator, input.len);

    for (0..input.len) |i| {
        try line.append(input[i][index]);
    }

    return line.toOwnedSlice();
}

fn getUpLeftDownRightLine(input: Input, index: usize) ![]u8 {
    var line = try ArrayList(u8).initCapacity(allocator, input.len);

    for (0..input.len) |i| {
        if (index + i == input[0].len) {
            try line.append('c');
        }
        try line.append(input[i][(index + i) % input[0].len]);
    }

    return line.toOwnedSlice();
}

fn getUpRightDownLeftLine(input: Input, index: usize) ![]u8 {
    var line = try ArrayList(u8).initCapacity(allocator, input.len + 1);

    for (0..input.len) |i| {
        try line.append(input[i][(index + (input[0].len - i)) % input[0].len]);
        if (index + (input[0].len - i) == input[0].len) {
            try line.append('c');
        }
    }

    return line.toOwnedSlice();
}

fn isXmas(kernel: [9]u8) bool {
    if (kernel[4] != 'A') {
        return false;
    }

    if ((kernel[0] == 'M' and kernel[8] == 'S') or (kernel[8] == 'M' and kernel[0] == 'S')) {
        if ((kernel[2] == 'M' and kernel[6] == 'S') or (kernel[6] == 'M' and kernel[2] == 'S')) {
            return true;
        }
    }

    return false;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = ArrayList([]u8).init(allocator);

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const slice = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, slice, line);

        try list.append(slice);
    }

    return list.toOwnedSlice();
}
