const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day1.txt";
const Input = struct {
    left: []i32,
    right: []i32,
};

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const input = readInput() catch |err| {
        try stdout.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    std.mem.sort(i32, input.left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, input.right, {}, comptime std.sort.asc(i32));

    try partOne(input);
    try partTwo(input);
}

fn partOne(input: Input) !void {
    var total_diff: i32 = 0;
    for (0..input.left.len) |i| {
        const diff = @abs(input.left[i] - input.right[i]);
        total_diff += @intCast(diff);
    }

    try stdout.print("Part one: {d}\n", .{total_diff});
}

fn partTwo(input: Input) !void {
    var score: u64 = 0;
    var left_index: usize = 0;
    var right_index: usize = 0;

    while (left_index < input.left.len) {
        const number = input.left[left_index];
        var counter: u64 = 0;

        while (right_index < input.right.len and input.right[right_index] <= number) {
            if (input.right[right_index] == number) {
                counter += 1;
            }

            right_index += 1;
        }

        var left_counter: usize = 0;
        while (left_index < input.left.len and input.left[left_index] == number) {
            left_counter += 1;
            left_index += 1;
        }

        //try stdout.print("{d} {d} {d}\n", .{ number, counter, left_counter });

        score += @as(u64, @intCast(number)) * counter * left_counter;
    }

    try stdout.print("Part two: {d}\n", .{score});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var left_list = ArrayList(i32).init(allocator);
    defer left_list.deinit();
    var right_list = ArrayList(i32).init(allocator);
    defer right_list.deinit();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const space_indices = spaces(line);

        try left_list.append(try std.fmt.parseInt(i32, line[0..space_indices.start], 10));
        try right_list.append(try std.fmt.parseInt(i32, line[space_indices.end..line.len], 10));
    }

    const left_slice = try left_list.toOwnedSlice();
    const right_slice = try right_list.toOwnedSlice();

    return .{
        .left = left_slice,
        .right = right_slice,
    };
}

fn spaces(line: []u8) struct { start: u8, end: u8 } {
    var start: u8 = 0;

    for (line, 0..) |char, i| {
        if (start == 0) {
            if (char == ' ') {
                start = @intCast(i);
            }
        } else {
            if (char != ' ') {
                return .{ .start = start, .end = @intCast(i) };
            }
        }
    }

    unreachable;
}
