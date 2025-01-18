const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day12.txt";

const Vec = struct {
    x: u32,
    y: u32,
};

const Unvisited = AutoHashMap(Vec, void);

const Fences = struct {
    top: AutoHashMap(Vec, void),
    bottom: AutoHashMap(Vec, void),
    left: AutoHashMap(Vec, void),
    right: AutoHashMap(Vec, void),
    size: Vec,

    pub fn init(alloc: Allocator, size: Vec) Fences {
        return Fences{
            .top = AutoHashMap(Vec, void).init(alloc),
            .bottom = AutoHashMap(Vec, void).init(alloc),
            .left = AutoHashMap(Vec, void).init(alloc),
            .right = AutoHashMap(Vec, void).init(alloc),
            .size = size,
        };
    }

    pub fn deinit(self: *Fences) void {
        self.top.deinit();
        self.bottom.deinit();
        self.left.deinit();
        self.right.deinit();
    }

    pub fn addTop(self: *Fences, position: Vec) !void {
        try self.top.put(position, undefined);
    }

    pub fn addBottom(self: *Fences, position: Vec) !void {
        try self.bottom.put(position, undefined);
    }

    pub fn addLeft(self: *Fences, position: Vec) !void {
        try self.left.put(position, undefined);
    }

    pub fn addRight(self: *Fences, position: Vec) !void {
        try self.right.put(position, undefined);
    }

    pub fn getTopSites(self: *const Fences) !u32 {
        var copy = try self.top.clone();

        var sites: u32 = 0;

        while (copy.count() > 0) {
            var key_iter = copy.keyIterator();
            const key = key_iter.next().?.*;
            _ = copy.remove(key);

            sites += 1;

            if (key.x > 0) {
                var to_left = key;
                to_left.x -= 1;

                while (copy.contains(to_left)) {
                    _ = copy.remove(to_left);

                    if (to_left.x == 0) {
                        break;
                    }

                    to_left.x -= 1;
                }
            }

            if (key.x < self.size.x) {
                var to_right = key;
                to_right.x += 1;

                while (copy.contains(to_right)) {
                    _ = copy.remove(to_right);

                    if (to_right.x == self.size.x) {
                        break;
                    }

                    to_right.x += 1;
                }
            }
        }

        return sites;
    }

    pub fn getBottomSites(self: *const Fences) !u32 {
        var copy = try self.bottom.clone();

        var sites: u32 = 0;

        while (copy.count() > 0) {
            var key_iter = copy.keyIterator();
            const key = key_iter.next().?.*;
            _ = copy.remove(key);

            sites += 1;

            if (key.x > 0) {
                var to_left = key;
                to_left.x -= 1;

                while (copy.contains(to_left)) {
                    _ = copy.remove(to_left);

                    if (to_left.x == 0) {
                        break;
                    }

                    to_left.x -= 1;
                }
            }

            if (key.x < self.size.x) {
                var to_right = key;
                to_right.x += 1;

                while (copy.contains(to_right)) {
                    _ = copy.remove(to_right);

                    if (to_right.x == self.size.x) {
                        break;
                    }

                    to_right.x += 1;
                }
            }
        }

        return sites;
    }

    pub fn getLeftSites(self: *const Fences) !u32 {
        var copy = try self.left.clone();

        var sites: u32 = 0;

        while (copy.count() > 0) {
            var key_iter = copy.keyIterator();
            const key = key_iter.next().?.*;
            _ = copy.remove(key);

            sites += 1;

            if (key.y > 0) {
                var to_top = key;
                to_top.y -= 1;

                while (copy.contains(to_top)) {
                    _ = copy.remove(to_top);

                    if (to_top.y == 0) {
                        break;
                    }

                    to_top.y -= 1;
                }
            }

            if (key.y < self.size.y) {
                var to_bottom = key;
                to_bottom.y += 1;

                while (copy.contains(to_bottom)) {
                    _ = copy.remove(to_bottom);

                    if (to_bottom.y == self.size.y) {
                        break;
                    }

                    to_bottom.y += 1;
                }
            }
        }

        return sites;
    }

    pub fn getRightSites(self: *const Fences) !u32 {
        var copy = try self.right.clone();

        var sites: u32 = 0;

        while (copy.count() > 0) {
            var key_iter = copy.keyIterator();
            const key = key_iter.next().?.*;
            _ = copy.remove(key);

            sites += 1;

            if (key.y > 0) {
                var to_top = key;
                to_top.y -= 1;

                while (copy.contains(to_top)) {
                    _ = copy.remove(to_top);

                    if (to_top.y == 0) {
                        break;
                    }

                    to_top.y -= 1;
                }
            }

            if (key.y < self.size.y) {
                var to_bottom = key;
                to_bottom.y += 1;

                while (copy.contains(to_bottom)) {
                    _ = copy.remove(to_bottom);

                    if (to_bottom.y == self.size.y) {
                        break;
                    }

                    to_bottom.y += 1;
                }
            }
        }

        return sites;
    }
};

const FenceSites = struct {
    top: bool,
    bottom: bool,
    left: bool,
    right: bool,
};

const Input = struct {
    garden: []u8,
    width: usize,

    pub fn getPlot(self: Input, x: usize, y: usize) u8 {
        return self.garden[x + y * self.width];
    }

    pub fn getHeigt(self: Input) usize {
        return self.garden.len / self.width;
    }

    pub fn calculateFenceCost(self: Input, bulk: bool) !u32 {
        var plots_to_visit = Unvisited.init(allocator);

        for (0..self.getHeigt()) |y| {
            for (0..self.width) |x| {
                try plots_to_visit.put(Vec{ .x = @intCast(x), .y = @intCast(y) }, undefined);
            }
        }

        var fence_cost: u32 = 0;

        while (plots_to_visit.count() != 0) {
            var key_iter = plots_to_visit.keyIterator();
            const key = key_iter.next().?.*;

            if (bulk) {
                var fences = Fences.init(allocator, Vec{ .x = @intCast(self.width), .y = @intCast(self.getHeigt()) });
                defer fences.deinit();

                const area = try self.recursiveSiteCountRegionSize(key, &plots_to_visit, &fences);
                const fence_sites = try fences.getTopSites() + try fences.getBottomSites() + try fences.getLeftSites() + try fences.getRightSites();

                fence_cost += area * fence_sites;
            } else {
                const result = self.recursiveBorderCountRegionSize(key, &plots_to_visit);

                fence_cost += result[0] * result[1];
            }
        }

        return fence_cost;
    }

    fn recursiveBorderCountRegionSize(self: Input, position: Vec, unvisited: *Unvisited) struct { u32, u32 } {
        const current_plant = self.getPlot(position.x, position.y);
        _ = unvisited.remove(position);

        var border: u32 = 0;
        var size: u32 = 1;

        if (self.getTopPlot(position)) |top| {
            const top_position = Vec{ .x = position.x, .y = position.y - 1 };

            if (current_plant != top) {
                border += 1;
            } else if (unvisited.contains(top_position)) {
                const result = self.recursiveBorderCountRegionSize(top_position, unvisited);
                border += result[0];
                size += result[1];
            }
        } else {
            border += 1;
        }

        if (self.getBottomPlot(position)) |bottom| {
            const bottom_position = Vec{ .x = position.x, .y = position.y + 1 };

            if (current_plant != bottom) {
                border += 1;
            } else if (unvisited.contains(bottom_position)) {
                const result = self.recursiveBorderCountRegionSize(bottom_position, unvisited);
                border += result[0];
                size += result[1];
            }
        } else {
            border += 1;
        }

        if (self.getLeftPlot(position)) |left| {
            const left_position = Vec{ .x = position.x - 1, .y = position.y };

            if (current_plant != left) {
                border += 1;
            } else if (unvisited.contains(left_position)) {
                const result = self.recursiveBorderCountRegionSize(left_position, unvisited);
                border += result[0];
                size += result[1];
            }
        } else {
            border += 1;
        }

        if (self.getRightPlot(position)) |right| {
            const right_position = Vec{ .x = position.x + 1, .y = position.y };

            if (current_plant != right) {
                border += 1;
            } else if (unvisited.contains(right_position)) {
                const result = self.recursiveBorderCountRegionSize(right_position, unvisited);
                border += result[0];
                size += result[1];
            }
        } else {
            border += 1;
        }

        return .{ border, size };
    }

    fn recursiveSiteCountRegionSize(self: Input, position: Vec, unvisited: *Unvisited, fences: *Fences) !u32 {
        const current_plant = self.getPlot(position.x, position.y);
        _ = unvisited.remove(position);

        var size: u32 = 1;

        if (self.getTopPlot(position)) |top| {
            const top_position = Vec{ .x = position.x, .y = position.y - 1 };

            if (current_plant != top) {
                try fences.addTop(position);
            } else if (unvisited.contains(top_position)) {
                size += try self.recursiveSiteCountRegionSize(top_position, unvisited, fences);
            }
        } else {
            try fences.addTop(position);
        }

        if (self.getBottomPlot(position)) |bottom| {
            const bottom_position = Vec{ .x = position.x, .y = position.y + 1 };

            if (current_plant != bottom) {
                try fences.addBottom(position);
            } else if (unvisited.contains(bottom_position)) {
                size += try self.recursiveSiteCountRegionSize(bottom_position, unvisited, fences);
            }
        } else {
            try fences.addBottom(position);
        }

        if (self.getLeftPlot(position)) |left| {
            const left_position = Vec{ .x = position.x - 1, .y = position.y };

            if (current_plant != left) {
                try fences.addLeft(position);
            } else if (unvisited.contains(left_position)) {
                size += try self.recursiveSiteCountRegionSize(left_position, unvisited, fences);
            }
        } else {
            try fences.addLeft(position);
        }

        if (self.getRightPlot(position)) |right| {
            const right_position = Vec{ .x = position.x + 1, .y = position.y };

            if (current_plant != right) {
                try fences.addRight(position);
            } else if (unvisited.contains(right_position)) {
                size += try self.recursiveSiteCountRegionSize(right_position, unvisited, fences);
            }
        } else {
            try fences.addRight(position);
        }

        return size;
    }

    fn getTopPlot(self: Input, position: Vec) ?u8 {
        if (position.y == 0) {
            return null;
        }

        return self.getPlot(position.x, position.y - 1);
    }

    fn getBottomPlot(self: Input, position: Vec) ?u8 {
        if (position.y >= self.getHeigt() - 1) {
            return null;
        }

        return self.getPlot(position.x, position.y + 1);
    }

    fn getLeftPlot(self: Input, position: Vec) ?u8 {
        if (position.x == 0) {
            return null;
        }

        return self.getPlot(position.x - 1, position.y);
    }

    fn getRightPlot(self: Input, position: Vec) ?u8 {
        if (position.x >= self.width - 1) {
            return null;
        }

        return self.getPlot(position.x + 1, position.y);
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
    try stdout.print("Part one: {d}\n", .{try input.calculateFenceCost(false)});
}

fn partTwo(input: Input) !void {
    try stdout.print("Part two: {d}\n", .{try input.calculateFenceCost(true)});
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var garden = ArrayList(u8).init(allocator);
    var width: usize = 0;

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        width = line.len;

        try garden.appendSlice(line);
    }

    return Input{ .garden = try garden.toOwnedSlice(), .width = width };
}
