const Register = @import("Register.zig").Register;
const Mem = @import("Memory.zig").MemoryBLock;
const CPU = @import("CPU.zig");
const ALU = @import("ALU.zig");
const OP = @import("OpCode.zig").OpCode;
const Operand = @import("OpCode.zig").Operand;
const std = @import("std");

const instruction_int = @import("OpCode.zig").instruction_int;


pub const ControlUnit = struct {
    program_counter: Register(u32) = .{ .data = 0 },
    intruction_register: Register(instruction_int) = .{ .data = 0 },
    memory_block: Mem,

    pub fn jump(self: *ControlUnit, target_line: u32) !void {
        if (target_line > self.memory_block.data.items.len) return error.JumpToNonExistingLine;

        self.program_counter.data = target_line;
    }

    pub fn jumpNotZero(self: *ControlUnit, target_line: u32) !void {
        if (CPU.general_purpose_registers[9].data == 0) return;

        try self.jump(target_line);
    }

    pub fn moveData(sender: *Operand, receiver: *Operand) void {

        if (sender.type == .IMMEDIATE) {
            std.debug.assert(receiver.value <= 9);
            CPU.general_purpose_registers[receiver.value].data = sender.value;
            return;
        }
        CPU.general_purpose_registers[receiver.value].data = CPU.general_purpose_registers[sender.value].data;
    }

    pub fn cycle(self: *ControlUnit) !void {
        self.program_counter.data = 1;
        
        while (self.program_counter.data < self.memory_block.data.items.len) : (self.program_counter.data += 1) {
            self.intruction_register.data = self.memory_block.data.items[self.program_counter.data - 1];

            var op_code = OP.decode(self.intruction_register.data);
            try op_code.run(self);
        }
    }
};