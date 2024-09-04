const Register = @import("Register.zig").Register;
const ALU = @import("ALU.zig");
const std = @import("std");
const CU = @import("ConctrolUnit.zig").ControlUnit;
const IO = @import("IOBlock.zig");
const Mnemonics = @import("Mnemonics.zig").Mnemonics;
const CPU = @import("CPU.zig");

const OperandType = enum {
    REGISTER,
    IMMEDIATE
};

pub const Operand = struct {
    type: OperandType = .REGISTER,
    value: u32 = 0
};

pub const instruction_int = @Type(.{
    .Int = .{
        .bits = @bitSizeOf(Mnemonics) + @bitSizeOf(Operand)*2,
        .signedness = .unsigned,
    },
});


pub const OpCode = struct {
    mnemonic: Mnemonics = Mnemonics.ADD,
    sender: Operand = .{},
    receiver: Operand = .{},

    /// Here we implicitly cast the registers datas to `instruction_int` to account for the bit shifting
    /// We encode by having :
    ///     <---@bitSizeOf(Mnemonics)(mnemonic)---><--@bitSizeOf(OperandType)(sender.type)--><----32bits(sender.value)-----><--@bitSizeOf(OperandType)(receiver.type)--><----32bits(receiver)----->
    pub fn encode(self: OpCode) instruction_int {
        var encoded: instruction_int = 0;
        var offset: u8 = 0;

        const receiver_data: instruction_int = self.receiver.value;
        encoded |= receiver_data ;
        offset += @bitSizeOf(@TypeOf(self.receiver.value));

        const receiver_metadata: instruction_int = @intFromEnum(self.receiver.type);
        encoded |= receiver_metadata << offset ;
        offset += @bitSizeOf(OperandType);

        const sender_data: instruction_int = self.sender.value;
        encoded |= sender_data << offset;
        offset += @bitSizeOf(@TypeOf(self.sender.value));

        const mode_value: instruction_int = @intFromEnum(self.sender.type);
        encoded |= mode_value << offset;
        offset += @bitSizeOf(OperandType);

        const mnemonic_value: instruction_int = @intFromEnum(self.mnemonic);
        encoded |= mnemonic_value << offset;

        return encoded;
    }

    pub fn decode(instruction: instruction_int) OpCode {
        var offset: u8 = 0;

        const bit_mask_32b: instruction_int = std.math.boolMask(u32, true);
        const bit_mask_meta: instruction_int = std.math.boolMask(std.meta.Int(.unsigned, @bitSizeOf(OperandType)), true);
        const bit_mask_mnemonic: instruction_int = std.math.boolMask(std.meta.Int(.unsigned, @bitSizeOf(Mnemonics)), true);

        const receiver_data: u32 = @intCast(instruction & bit_mask_32b);
        offset += 32;

        const mask = bit_mask_meta << offset;
        const receiver_metadata: u32 = @intCast((instruction & mask) >> offset);
        offset += @bitSizeOf(OperandType);

        const sender_data: u32 = @intCast((instruction & (bit_mask_32b << offset)) >> offset);
        offset += 32;

        const sender_metadata: u32 = @intCast((instruction & (bit_mask_32b << offset)) >> offset);
        offset += @bitSizeOf(OperandType);

        const mnemonic = (instruction & (bit_mask_mnemonic << offset)) >> offset;

        return .{
            .mnemonic = @enumFromInt(mnemonic),
            .sender = .{
                .type = @enumFromInt(sender_metadata),
                .value = sender_data
            },
            .receiver = .{
                .type = @enumFromInt(receiver_metadata),
                .value = receiver_data
            },
        };
    }

    pub fn run(self: *OpCode, control_unit: *CU) !void {
        const a = if (self.sender.type == .IMMEDIATE) self.sender.value else CPU.general_purpose_registers[self.sender.value].data;
        const b = if (self.receiver.type == .IMMEDIATE) self.receiver.value else CPU.general_purpose_registers[self.receiver.value].data;

        switch (self.mnemonic) {
            .ADD => { ALU.addition(a, b); },
            .SUB => { ALU.subtraction(a, b); },
            .MUL => { ALU.multiplication(a, b); },
            .DIV => { ALU.division(a, b); },
            .MOD => { ALU.modulo(a, b); },
            .INC => { ALU.increment(self.sender.value); },
            .DEC => { ALU.decrement(self.sender.value); },
            .AND => { ALU.logicAnd(a, b); },
            .NOT => { ALU.logicNot(a); },
            .OR =>  { ALU.logicOr(a, b); },
            .XOR => { ALU.logicXor(a, b); },
            .LS =>  { ALU.leftShift(a); },
            .RS =>  { ALU.rightShift(a); },

            .MOV => { CU.moveData(&self.sender, &self.receiver); },
            .JMP => { try control_unit.jump(a); },
            .JNZ => { try control_unit.jumpNotZero(a); },

            .OUT => { try IO.printAsNum(a); },
            .OUTC => { try IO.printAsChar(a); },
            .IN => { IO.scan(self.sender.value); },

            .NOTHING => {},
        }
    }
};


test "encoding" {
    var op = OpCode{
        .mnemonic = .ADD,
        .sender = .{
            .type = .REGISTER,
            .value = 5
        },
        .receiver = .{
            .type = .REGISTER,
            .value = 15
        },
    };

    try std.testing.expectEqual(0b00000_0_00000000000000000000000000000101_0_00000000000000000000000000001111, op.encode());

    op = OpCode{
        .mnemonic = .MOV,
        .sender = .{
            .type = .IMMEDIATE,
            .value = 5
        },
        .receiver = .{
            .type = .REGISTER,
            .value = 9
        },
    };


    std.debug.print("{any}", .{OpCode.decode(op.encode())});
    // 11011_0_00000000000000000000000000001010_0_00000000000000000000000000001001


    try std.testing.expectEqual(op, OpCode.decode(op.encode()));
}

test "decoding" {
    const op = OpCode{
        .mnemonic = .ADD,
        .sender = .{
            .type = .REGISTER,
            .value = 5
        },
        .receiver = .{
            .type = .REGISTER,
            .value = 15
        },
    };

    try std.testing.expectEqual(op, OpCode.decode(0b00000_0_00000000000000000000000000000101_0_00000000000000000000000000001111));
}