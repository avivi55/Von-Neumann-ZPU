const std = @import("std");
const Allocator = std.mem.Allocator;
const OpCode = @import("OpCode.zig").OpCode;
const instruction_int = @import("OpCode.zig").instruction_int;
const AssemblyParser = @import("AssemblyParser.zig");

pub const MemoryBLock = struct {
    data: std.ArrayList(instruction_int),
    allocator: Allocator,

    pub fn init(allocator: Allocator) MemoryBLock {
        return .{
            .data = std.ArrayList(instruction_int).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: MemoryBLock) void {
        self.data.deinit();
    }

    pub fn loadAssemblyFile(self: *MemoryBLock, path: []const u8) !void {
        var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
        const absolutePath = try std.fs.realpath(path, &path_buffer);

        const file = try std.fs.openFileAbsolute(absolutePath, .{ .mode = .read_only });
        defer file.close();

        const file_buffer = file.reader().readAllAlloc(self.allocator, 10_000) catch |err| {
            if (err == error.StreamTooLong) {
                std.log.info("[INFO] File might be too big to parse, the internal file buffer is 10,000 characters", .{});
            }
            return err;
        };
        defer self.allocator.free(file_buffer);

        var iter = std.mem.splitSequence(u8, file_buffer, "\n");

        while (iter.next()) |line| {
            try self.data.append(OpCode.encode(AssemblyParser.parseLine(line) catch |e|  {
                std.debug.print("[Error] @ line {d} ({s})\n", .{iter.index.? - 1, absolutePath});
                return e;
            }));
        }
    }
};


test "parsing" {
    var mem: MemoryBLock = MemoryBLock.init(std.testing.allocator);
    defer mem.deinit();

    try mem.loadAssemblyFile("./assembly/fibonacci.s");
}