const std = @import("std");
const Register = @import("Register.zig").Register;
const Mem = @import("Memory.zig").MemoryBLock;
const CU = @import("ConctrolUnit.zig").ControlUnit;

pub var general_purpose_registers: [10]Register(u32) = .{ .{ .data = 0 } } ** 10;

pub fn run(path: []const u8) !void {
    const allocator = std.heap.page_allocator;

    var memory = Mem.init(allocator);
    try memory.loadAssemblyFile(path);


    var control_unit = CU{
        .memory_block = memory
    };

    try control_unit.cycle();

    std.debug.print("\n", .{});
}