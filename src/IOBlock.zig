const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut();

const Register = @import("Register.zig").Register;
const cpu = @import("CPU.zig");

pub fn scan(gpr_index: u32) void {
    std.debug.assert(gpr_index <= 9);

    while (true) {
        stdout.writeAll("Enter input:") catch {};

        var buffer: [100]u8 = undefined;
        const input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch "" orelse "";

        cpu.general_purpose_registers[gpr_index].data = std.fmt.parseInt(u32, input, 10) catch |e| {
            switch (e) {
                error.Overflow => {
                    std.debug.print("\nInterger overflew (the input is 32bit), please retry :", .{});
                    continue;
                },
                error.InvalidCharacter => {
                    std.debug.print("\nInvalid input, please retry :", .{});
                    continue;
                }
            }
        };

        break;
    }
}

pub fn printAsNum(a: u32) !void {
    try std.io.getStdOut().writer().print("{d}", .{a});
}

pub fn printAsChar(a: u32) !void {
    const new_a: u8 = @truncate(a);
    try std.io.getStdOut().writer().print("{c}", .{new_a});
}
