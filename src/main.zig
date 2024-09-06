const std = @import("std");
const CPU = @import("CPU.zig");

pub fn main() !void {

    try CPU.run("./assembly/equation.s");

}