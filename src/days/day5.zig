const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day5.txt";
const Rules = AutoHashMap(u16, []u16);
const Update = []u16;
const Input = struct {
    rules: Rules,
    updates: []Update,
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
    var sum: u16 = 0;

    for (input.updates) |update| {
        var is_good = true;

        var i = update.len;
        while (i > 0 and is_good) {
            i -= 1;

            const number = update[i];
            const before = update[0..i];

            for (before) |forbidden| {
                if (isNumberForbiddenBefore(&input.rules, number, forbidden)) {
                    is_good = false;
                    break;
                }
            }
        }

        if (is_good) {
            sum += getMiddleNumber(update);
        }
    }

    try stdout.print("Part one: {d}\n", .{sum});
}

fn partTwo(input: Input) !void {
    var sum: u16 = 0;

    for (input.updates) |update| {
        var is_good = true;

        var i = update.len;
        while (i > 0 and is_good) {
            i -= 1;

            const number = update[i];
            const before = update[0..i];

            for (before) |forbidden| {
                if (isNumberForbiddenBefore(&input.rules, number, forbidden)) {
                    is_good = false;
                    break;
                }
            }
        }

        if (!is_good) {
            const reorderedUpdate = try reodrderUpdate(update, &input.rules);

            sum += getMiddleNumber(reorderedUpdate);
            allocator.free(reorderedUpdate);
        }
    }

    try stdout.print("Part two: {d}\n", .{sum});
}

fn isNumberForbiddenBefore(rules: *const Rules, number: u16, forbidden: u16) bool {
    if (rules.contains(number)) {
        const forbidden_before = rules.get(number).?;

        for (forbidden_before) |element| {
            if (element == forbidden) {
                return true;
            }
        }
    }

    return false;
}

fn getMiddleNumber(update: Update) u16 {
    return update[update.len / @as(usize, 2)];
}

fn reodrderUpdate(update: Update, rules: *const Rules) !Update {
    var new_update = try allocator.alloc(u16, update.len);
    std.mem.copyForwards(u16, new_update, update);

    var i = new_update.len;
    while (i > 0) {
        i -= 1;

        const number = new_update[i];
        const before = new_update[0..i];

        for (before, 0..) |forbidden, before_index| {
            if (isNumberForbiddenBefore(rules, number, forbidden)) {
                for (before_index..i) |inner| {
                    new_update[inner] = new_update[inner + 1];
                }

                new_update[i] = forbidden;

                i = new_update.len;
                break;
            }
        }
    }

    return new_update;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var rules_mode = true;
    var rules = Rules.init(allocator);
    var updates = ArrayList(Update).init(allocator);

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            rules_mode = false;
            continue;
        }

        if (rules_mode) {
            var numbers = std.mem.splitScalar(u8, line, '|');
            const before = try std.fmt.parseInt(u16, numbers.next().?, 10);
            const after = try std.fmt.parseInt(u16, numbers.next().?, 10);

            if (rules.contains(before)) {
                const slice = rules.get(before).?;
                const len = slice.len;

                const new_slice = try allocator.realloc(slice, len + 1);
                std.mem.copyForwards(u16, new_slice, slice);
                new_slice[len] = after;

                try rules.put(before, new_slice);
            } else {
                const slice = try allocator.alloc(u16, 1);
                slice[0] = after;
                try rules.put(before, slice);
            }
        } else {
            var numbers = std.mem.splitScalar(u8, line, ',');
            var update = ArrayList(u16).init(allocator);

            while (numbers.next()) |number| {
                try update.append(try std.fmt.parseInt(u16, number, 10));
            }

            try updates.append(try update.toOwnedSlice());
        }
    }

    return .{ .rules = rules, .updates = try updates.toOwnedSlice() };
}
