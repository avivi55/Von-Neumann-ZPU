const OpCode = @import("OpCode.zig").OpCode;
const Operand = @import("OpCode.zig").Operand;
const Mnemonics = @import("Mnemonics.zig").Mnemonics;
const CPU = @import("CPU.zig");

const std = @import("std");

const FirstOperandErrors = error{
    FirstOperand_RegisterNumberIsNotANumeral,
    FirstOperand_RegisterNumberOutOfBounds,
    FirstOperand_ImmediateOutOfBounds,
    FirstOperand_InvalidFirstCharacter,
    FirstOperand_Malformation,
    FirstOperand_InvalidCharImmediateFormat,
    FirstOperand_InvalidNumImmediateFormat,
};

const SecondOperandErrors = error{
    SecondOperand_NotARegister,
    SecondOperand_RegisterNumberIsNotANumeral,
    SecondOperand_RegisterNumberOutOfBounds,
    SecondOperand_Malformation,
};

pub const AssemblyParsingError = error{
    ToMuchOperands,
    IncorrectInstruction,
    NoInstruction,
} || FirstOperandErrors || SecondOperandErrors;


pub fn parseLine(line: []const u8) AssemblyParsingError!OpCode {
    if (isInsignificantLine(line)) {
        return OpCode{ .mnemonic = .NOTHING };
    }


    var space_splitted_line = std.mem.splitSequence(u8, line, " ");

    const supposed_instuction = space_splitted_line.first();
    const supposed_sender = space_splitted_line.next();
    const supposed_receiver = space_splitted_line.next();

    if (space_splitted_line.next()) |_| return AssemblyParsingError.ToMuchOperands;

    if (space_splitted_line.buffer.len == 0) return AssemblyParsingError.NoInstruction;

    const instruction = try getInstruction(supposed_instuction);

    return .{
        .mnemonic = instruction,
        .sender = try process_sender(supposed_sender),
        .receiver = try process_receiver(supposed_receiver),
    };
}

fn isInsignificantLine(line: []const u8) bool {
    return line.len < 1 or line[0] == '#';
}

fn getInstruction(supposed_instruction: []const u8) AssemblyParsingError!Mnemonics {
    var buf: [4]u8 = undefined;
    const uppercase_supposed_instruction = std.ascii.upperString(&buf, supposed_instruction);
    return std.meta.stringToEnum(Mnemonics, uppercase_supposed_instruction) orelse  AssemblyParsingError.IncorrectInstruction;
}

fn process_sender(supposed_sender: ?[]const u8) AssemblyParsingError!Operand {
    if (supposed_sender) |sender| {
        if (sender.len < 2) {
            std.debug.print("First(sender) operand has a length less than 2: \"{s}\" Cannot interpret the meaning\n", .{sender});
            return AssemblyParsingError.FirstOperand_Malformation;
        }

        var result = Operand{};

        switch (sender[0]) {
            'r', 'R' => {
                result.type = .REGISTER;
                result.value = std.fmt.parseUnsigned(u32, sender[1..], 10) catch {
                    std.debug.print("Error while parsing register number: \"{s}\"\n", .{sender[1..]});
                    return AssemblyParsingError.FirstOperand_RegisterNumberIsNotANumeral;
                };
                if (result.value >= CPU.general_purpose_registers.len){
                    std.debug.print("Register number: \"{s}\" is out of bounds of the general purpose registers(10)\n", .{sender[1..]});
                    return AssemblyParsingError.FirstOperand_RegisterNumberOutOfBounds;
                }
            },
            '$' => {
                result.type = .IMMEDIATE;

                if (std.fmt.parseUnsigned(u32, sender[1..], 10)) |parsed| {
                    result.value = parsed;
                } else |e| finished: {

                    if (e == error.Overflow) {
                        std.debug.print("Immediate value out of bounds (32 bits): \"{s}\"\n", .{sender[1..]});
                        return AssemblyParsingError.FirstOperand_ImmediateOutOfBounds;
                    }

                    if (e != error.InvalidCharacter) {
                        std.debug.print("Error while parsing immediate number: \"{s}\"\n", .{sender[1..]});
                        return AssemblyParsingError.FirstOperand_InvalidNumImmediateFormat;
                    }

                    if (sender.len == 2) {
                        result.value = sender[1];
                        break :finished;
                    }

                    if (sender.len != 3) {
                        std.debug.print("Char immediate to long or to short: \"{s}\"\n", .{sender});
                        return AssemblyParsingError.FirstOperand_InvalidCharImmediateFormat;
                    }

                    if (sender[1] == '\\') {
                        switch (sender[2]) {
                            's' => result.value = ' ',
                            'n' => result.value = '\n',
                            else => {
                                std.debug.print("Char immediate malformed: \"{s}\"\n", .{sender});
                                return AssemblyParsingError.FirstOperand_InvalidCharImmediateFormat;
                            }
                        }
                    }
                }
            },
            else => { return AssemblyParsingError.FirstOperand_InvalidFirstCharacter; }
        }

        return result;
    }

    return .{
        .type = .REGISTER,
        .value = 0,
    };
}

fn process_receiver(supposed_receiver: ?[]const u8) AssemblyParsingError!Operand {
    if (supposed_receiver) |receiver| {
        if (receiver.len < 2) {
            std.debug.print("Second(receiver) operand has a length less than 2: \"{s}\" Cannot interpret the meaning\n", .{receiver});
            return AssemblyParsingError.SecondOperand_Malformation;
        }

        var result = Operand{
            .type = .REGISTER
        };

        if (receiver[0] != 'r' and receiver[0] != 'R') {
            std.debug.print("Second(receiver) operand MUST be a register (start with 'R' or 'r'): \"{s}\"\n", .{receiver});
            return AssemblyParsingError.SecondOperand_NotARegister;
        }

        result.value = std.fmt.parseUnsigned(u32, receiver[1..], 10) catch {
            std.debug.print("Error while parsing register number: \"{s}\"\n", .{receiver[1..]});
            return AssemblyParsingError.SecondOperand_RegisterNumberIsNotANumeral;
        };
        if (result.value >= CPU.general_purpose_registers.len){
            std.debug.print("Register number: \"{s}\" is out of bounds of the general purpose registers(10)\n", .{receiver[1..]});
            return AssemblyParsingError.SecondOperand_RegisterNumberOutOfBounds;
        }

        return result;
    }

    return .{
        .type = .REGISTER,
        .value = 1,
    };
}

test "empty line" {
    const empty_line = "";
    const parsing_result = try parseLine(empty_line);

    try std.testing.expectEqual(Mnemonics.NOTHING, parsing_result.mnemonic);
}

test "comment line" {
    const commented_line = "# yes I love cats";
    const parsing_result = try parseLine(commented_line);

    try std.testing.expectEqual(Mnemonics.NOTHING, parsing_result.mnemonic);
}

test "to much operands" {
    const error_line = "MOV r21 r21 r21";
    const parsing_result = parseLine(error_line);

    try std.testing.expectError(AssemblyParsingError.ToMuchOperands, parsing_result);
}

test "process sender" {
    std.debug.print("{any}", .{try process_receiver("R1")});
}
