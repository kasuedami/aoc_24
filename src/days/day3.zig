const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day3.txt";
const Mul = struct { u32, u32 };
const Input = []u8;

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
    const muls = findMultiplications(input);
    var total: u32 = 0;
    for (muls) |mul| {
        total += mul[0] * mul[1];
    }

    try stdout.print("Part one: {d}\n", .{total});
}

fn partTwo(input: Input) !void {
    const muls = findMultiplications(try filterOutDonts(input));
    var total: u32 = 0;
    for (muls) |mul| {
        total += mul[0] * mul[1];
    }

    try stdout.print("Part one: {d}\n", .{total});
}

fn findMultiplications(seq: []u8) []Mul {
    var tokens = std.mem.splitSequence(u8, seq, "mul(");
    _ = tokens.next();

    var list = ArrayList(Mul).init(allocator);
    defer list.deinit();

    while (tokens.next()) |token| {
        const mul = extractMul(token);

        if (mul != null) {
            list.append(mul.?) catch unreachable;
        }
    }

    return list.toOwnedSlice() catch unreachable;
}

fn extractMul(seq: []const u8) ?Mul {
    const first_num = getNumber(seq);

    if (first_num == null) {
        return null;
    }

    if (seq[first_num.?[1] + 1] != ',') {
        return null;
    }

    const second_num = getNumber(seq[first_num.?[1] + 2 ..]);

    if (second_num == null) {
        return null;
    }

    if (seq[first_num.?[1] + second_num.?[1] + 3] != ')') {
        return null;
    }

    return .{ first_num.?[0], second_num.?[0] };
}

fn getNumber(seq: []const u8) ?struct { u16, usize } {
    if (!std.ascii.isDigit(seq[0])) {
        return null;
    }

    var end: u16 = 0;
    while (end < seq.len) {
        if (std.ascii.isDigit(seq[end + 1])) {
            end += 1;
        } else {
            break;
        }
    }

    return .{ std.fmt.parseInt(u16, seq[0 .. end + 1], 10) catch unreachable, end };
}

fn filterOutDonts(seq: []u8) ![]u8 {
    var dos = std.mem.splitSequence(u8, seq, "do()");

    var dos_only = ArrayList(u8).init(allocator);
    defer dos_only.deinit();

    while (dos.next()) |do| {
        var split = std.mem.splitSequence(u8, do, "don't()");

        if (split.next()) |enabled| {
            try dos_only.appendSlice(enabled);
        }
    }

    return dos_only.toOwnedSlice();
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = ArrayList(u8).init(allocator);
    defer list.deinit();

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try list.appendSlice(line);
        try list.append('\n');
    }

    return list.toOwnedSlice();
}
