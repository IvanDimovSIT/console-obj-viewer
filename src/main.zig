const std = @import("std");
const Io = std.Io;

const obj_parser_mod = @import("obj_parser.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const test_file_name = "test_model.obj";
    const test_file_contents = try readFile(io, gpa, test_file_name);
    defer gpa.free(test_file_contents);

    const model = try obj_parser_mod.parseObjFile(gpa, test_file_contents);
    defer model.deinit(gpa);
    std.debug.print("Parsed file\n{}\n", .{model});
}

fn readFile(io: Io, allocator: std.mem.Allocator, file_name: []const u8) ![]const u8 {
    const cwd = Io.Dir.cwd();
    return try cwd.readFileAlloc(io, file_name, allocator, .unlimited);
}

comptime {
    _ = @import("obj_parser.zig");
}
