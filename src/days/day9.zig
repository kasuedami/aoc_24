const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day9.txt";

const Input = []?u32;

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
    const compressed = try calculateCompressedFragmented(input);
    defer allocator.free(compressed);

    var checksum: u64 = 0;

    for (compressed, 0..) |n, i| {
        if (n != null) {
            checksum += n.? * @as(u32, @intCast(i));
        }
    }

    try stdout.print("Part one: {d}\n", .{checksum});
}

fn partTwo(input: Input) !void {
    const compressed = try calculateCompressedUnfragmented(input);
    defer allocator.free(compressed);

    var checksum: u64 = 0;

    for (compressed, 0..) |n, i| {
        if (n != null) {
            checksum += n.? * @as(u32, @intCast(i));
        }
    }

    try stdout.print("Part two: {d}\n", .{checksum});
}

fn calculateCompressedFragmented(input: Input) ![]?u32 {
    var front_index: usize = 0;
    var back_index = input.len - 1;

    var result = try allocator.alloc(?u32, input.len);
    std.mem.copyForwards(?u32, result, input);

    while (true) {
        while (result[front_index] != null) {
            front_index += 1;
        }

        while (result[back_index] == null) {
            back_index -= 1;
        }

        if (front_index > back_index) {
            break;
        }

        result[front_index] = result[back_index];
        result[back_index] = null;

        front_index += 1;
        back_index -= 1;
    }

    return result;
}

fn calculateCompressedUnfragmented(input: Input) ![]?u32 {
    var back_index = input.len - 1;

    var result = try allocator.alloc(?u32, input.len);
    std.mem.copyForwards(?u32, result, input);

    while (true) {
        while (result[back_index] == null) {
            back_index -= 1;
        }

        const back_block_end = back_index;
        const back_block_id = result[back_index];

        while (result[back_index] != null and result[back_index].? == back_block_id and back_index > 0) {
            back_index -= 1;
        }

        const back_block_size = back_block_end - back_index;

        var front_index: usize = 0;
        var free_block_start: usize = 0;
        var can_copy = false;

        while (true) {
            while (result[front_index] != null and front_index <= back_index + 1) {
                front_index += 1;
            }

            free_block_start = front_index;

            while (result[front_index] == null and front_index <= back_index + 1) {
                front_index += 1;
            }

            if (front_index - 1 > back_index) {
                break;
            }

            const free_block_size: usize = front_index - free_block_start;

            if (free_block_size >= back_block_size) {
                can_copy = true;
                break;
            }
        }

        if (can_copy) {
            for (0..back_block_size) |i| {
                result[free_block_start + i] = back_block_id;
            }

            for (0..back_block_size) |i| {
                result[back_index + 1 + i] = null;
            }
        }

        if (back_index == 0) {
            break;
        }
    }

    return result;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var current_block: u32 = 0;
    var file_block = true;

    var list = ArrayList(?u32).init(allocator);

    while (true) {
        const c = in_stream.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        if (c < 48 or c > 58) {
            break;
        }

        const block_size = c - 48;

        for (0..block_size) |_| {
            if (file_block) {
                try list.append(current_block);
            } else {
                try list.append(null);
            }
        }

        if (file_block) {
            current_block += 1;
        }

        file_block = !file_block;
    }

    return list.toOwnedSlice();
}
