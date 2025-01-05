const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day2.txt";
const Input = [][]i8;

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
    var safe_reports: u16 = 0;
    for (input) |report| {
        if (isReportSafe(report)) {
            safe_reports += 1;
        }
    }

    try stdout.print("Part one: {d}\n", .{safe_reports});
}

fn partTwo(input: Input) !void {
    var safe_reports: u16 = 0;
    for (input) |report| {
        if (isReportSavable(report)) {
            safe_reports += 1;
        }
    }

    try stdout.print("Part two: {d}\n", .{safe_reports});
}

fn isReportSafe(report: []i8) bool {
    var first = report[0];
    var second = report[1];

    if (first == second or @abs(first - second) > 3) {
        return false;
    }

    const increasing = second > first;

    for (1..report.len - 1) |i| {
        first = report[i];
        second = report[i + 1];

        const diff = second - first;

        switch (diff) {
            -3...-1 => {
                if (increasing) {
                    return false;
                }
            },
            1...3 => {
                if (!increasing) {
                    return false;
                }
            },
            else => {
                return false;
            },
        }
    }

    return true;
}

fn isReportSavable(report: []i8) bool {
    var first = report[0];
    var second = report[1];

    if (first == second or @abs(first - second) > 3) {
        return isReportSafe(reportRemoveValue(report, 0)) or isReportSafe(reportRemoveValue(report, 1));
    }

    const increasing = second > first;

    for (1..report.len - 1) |i| {
        first = report[i];
        second = report[i + 1];

        const diff = second - first;

        switch (diff) {
            -3...-1 => {
                if (increasing) {
                    return checkNearestNumberRemovedReport(report, i);
                }
            },
            1...3 => {
                if (!increasing) {
                    return checkNearestNumberRemovedReport(report, i);
                }
            },
            else => {
                return checkNearestNumberRemovedReport(report, i);
            },
        }
    }

    return true;
}

fn checkNearestNumberRemovedReport(report: []i8, index: usize) bool {
    return isReportSafe(reportRemoveValue(report, index - 1)) or isReportSafe(reportRemoveValue(report, index)) or isReportSafe(reportRemoveValue(report, index + 1));
}

fn reportRemoveValue(report: []i8, index: usize) []i8 {
    var shortend = ArrayList(i8).init(allocator);
    defer shortend.deinit();

    for (report, 0..) |element, i| {
        if (i == index) {
            continue;
        }

        shortend.append(element) catch unreachable;
    }

    return shortend.toOwnedSlice() catch unreachable;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var list = ArrayList([]i8).init(allocator);
    defer list.deinit();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try list.append(try lineToData(line));
    }

    return list.toOwnedSlice();
}

fn lineToData(line: []u8) ![]i8 {
    var iter = std.mem.splitScalar(u8, line, ' ');

    var data = ArrayList(i8).init(allocator);
    defer data.deinit();

    while (iter.next()) |number| {
        try data.append(try std.fmt.parseInt(i8, number, 10));
    }

    return data.toOwnedSlice();
}
