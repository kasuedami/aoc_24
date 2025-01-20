const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const Days = enum {
        day1,
        day2,
        day3,
        day4,
        day5,
        day6,
        day7,
        day8,
        day9,
        day10,
        day11,
        day12,
        day13,
    };

    const day_option = b.option(Days, "day", "day to run") orelse .day13;
    const day_step = b.step("day", "Run day");
    const day = b.addExecutable(.{
        .name = "day",
        .root_source_file = b.path(b.fmt("src/days/{s}.zig", .{@tagName(day_option)})),
        .target = target,
        .optimize = optimize,
    });

    const day_run = b.addRunArtifact(day);
    day_step.dependOn(&day_run.step);
}
