const cpu = @import("CPU.zig");
const std = @import("std");
const testing = std.testing;

pub const accumulator = &cpu.general_purpose_registers[0];

pub fn addition(a: u32, b: u32) void { accumulator.data = a +% b; }

pub fn subtraction(a: u32, b: u32) void { accumulator.data = a -% b; }

pub fn multiplication(a: u32, b: u32) void { accumulator.data = a *% b; }

pub fn division(a: u32, b: u32) void { accumulator.data = a / b; }

pub fn increment(a: u32) void { cpu.general_purpose_registers[a].data +%= 1; }

pub fn decrement(a: u32) void { cpu.general_purpose_registers[a].data -%= 1; }

pub fn modulo(a: u32, b: u32) void { accumulator.data = a % b; }

pub fn logicAnd(a: u32, b: u32) void { accumulator.data = a & b; }

pub fn logicOr(a: u32, b: u32) void { accumulator.data = a | b; }

pub fn logicXor(a: u32, b: u32) void { accumulator.data = a ^ b; }

pub fn logicNot(a: u32) void { accumulator.data = ~a; }

pub fn leftShift(a: u32) void { accumulator.data = a << 1; }

pub fn rightShift(a: u32) void { accumulator.data = a >> 1; }


test "accumulator integrity" {
    const a = 32;
    const b = 10;

    addition(a, b);
    try testing.expectEqual(42, cpu.general_purpose_registers[0].data);

    subtraction(a, b);
    try testing.expectEqual(22, cpu.general_purpose_registers[0].data);

    multiplication(a, b);
    try testing.expectEqual(320, cpu.general_purpose_registers[0].data);

    division(a, b);
    try testing.expectEqual(3, cpu.general_purpose_registers[0].data);

    modulo(a, b);
    try testing.expectEqual(2, cpu.general_purpose_registers[0].data);

    logicAnd(a, b);
    try testing.expectEqual(0b0000_000, cpu.general_purpose_registers[0].data);

    logicOr(a, b);
    try testing.expectEqual(0b0010_1010, cpu.general_purpose_registers[0].data);

    leftShift(a);
    try testing.expectEqual(0b0100_0000, cpu.general_purpose_registers[0].data);

    rightShift(a);
    try testing.expectEqual(0b0001_0000, cpu.general_purpose_registers[0].data);

    logicNot(a);
    try testing.expectEqual(0xffff_ff00 | 0b1101_1111, cpu.general_purpose_registers[0].data);

    logicXor(a, b);
    try testing.expectEqual( 0b0010_1010, cpu.general_purpose_registers[0].data);
}