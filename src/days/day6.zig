const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const allocator = std.heap.page_allocator;

const input_path = "inputs/day6.txt";

const Vec = struct {
    x: i32,
    y: i32,
};

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Guard = struct {
    position: Vec,
    direction: Direction,
};

const Obstacles = AutoHashMap(Vec, void);

const Input = struct {
    guard: Guard,
    size: Vec,
    obstacles: Obstacles,
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
    var running_guard = input.guard;
    var visited = AutoHashMap(Vec, void).init(allocator);
    defer visited.deinit();

    while (inBounds(running_guard.position, input.size)) {
        const newly_visited = try moveGuard(&running_guard, &input.obstacles, input.size);
        for (newly_visited) |new| {
            try visited.put(new, undefined);
        }

        rotateGuard(&running_guard);
    }

    try stdout.print("Part one: {d}\n", .{visited.count()});
}

fn partTwo(input: Input) !void {
    var running_guard = input.guard;
    var visited = AutoHashMap(Vec, void).init(allocator);
    defer visited.deinit();

    while (inBounds(running_guard.position, input.size)) {
        const newly_visited = try moveGuard(&running_guard, &input.obstacles, input.size);
        for (newly_visited) |new| {
            try visited.put(new, undefined);
        }

        rotateGuard(&running_guard);
    }

    _ = visited.remove(input.guard.position);

    var iter = visited.iterator();
    var loop_counter: u32 = 0;

    while (iter.next()) |position| {
        var new_obstacles = try input.obstacles.clone();
        try new_obstacles.put(position.key_ptr.*, undefined);

        running_guard = input.guard;

        var guard_states = AutoHashMap(Guard, void).init(allocator);
        defer guard_states.deinit();

        var loop_detected = false;

        while (inBounds(running_guard.position, input.size) and !loop_detected) {
            const newly_visited = try moveGuard(&running_guard, &new_obstacles, input.size);

            for (newly_visited) |new| {
                const guard_state = Guard{ .position = new, .direction = running_guard.direction };
                if (guard_states.contains(guard_state)) {
                    loop_counter += 1;
                    loop_detected = true;

                    break;
                }

                try guard_states.put(Guard{ .position = new, .direction = running_guard.direction }, undefined);
            }

            rotateGuard(&running_guard);
        }
    }

    try stdout.print("Part two: {d}\n", .{loop_counter});
}

fn moveGuard(guard: *Guard, obstacles: *const Obstacles, size: Vec) ![]Vec {
    var hit_wall = false;
    var visited = ArrayList(Vec).init(allocator);

    while (!hit_wall) {
        var position_to_check = guard.position;

        switch (guard.direction) {
            Direction.up => {
                position_to_check.y -= 1;
            },
            Direction.down => {
                position_to_check.y += 1;
            },
            Direction.left => {
                position_to_check.x -= 1;
            },
            Direction.right => {
                position_to_check.x += 1;
            },
        }

        if (obstacles.contains(position_to_check)) {
            hit_wall = true;
            break;
        }

        try visited.append(guard.position);
        guard.position = position_to_check;

        if (!inBounds(position_to_check, size)) {
            return visited.toOwnedSlice();
        }
    }

    return visited.toOwnedSlice();
}

fn rotateGuard(guard: *Guard) void {
    switch (guard.direction) {
        Direction.up => {
            guard.direction = Direction.right;
        },
        Direction.right => {
            guard.direction = Direction.down;
        },
        Direction.down => {
            guard.direction = Direction.left;
        },
        Direction.left => {
            guard.direction = Direction.up;
        },
    }
}

fn inBounds(position: Vec, size: Vec) bool {
    return position.x >= 0 and position.x < size.x and position.y >= 0 and position.y < size.y;
}

fn readInput() !Input {
    var file = try std.fs.cwd().openFile(input_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var guard: Guard = undefined;
    var size = Vec{ .x = 0, .y = 0 };
    var obstacles = Obstacles.init(allocator);

    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line, 0..) |c, i| {
            const position = Vec{ .x = @intCast(i), .y = size.y };

            switch (c) {
                '#' => {
                    try obstacles.put(position, undefined);
                },
                '>' => {
                    guard = .{ .position = position, .direction = Direction.right };
                },
                '<' => {
                    guard = .{ .position = position, .direction = Direction.left };
                },
                '^' => {
                    guard = .{ .position = position, .direction = Direction.up };
                },
                'v' => {
                    guard = .{ .position = position, .direction = Direction.down };
                },
                else => {},
            }
        }

        size.x = @intCast(line.len);
        size.y += 1;
    }

    return .{ .guard = guard, .size = size, .obstacles = obstacles };
}
