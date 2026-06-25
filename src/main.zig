const std = @import("std");
const Io = std.Io;
const transformations = @import("transformations.zig");
const Canvas = @import("Canvas.zig");
const WireframeRenderer = @import("WireframeRenderer.zig");

const obj_parser_mod = @import("obj_parser.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const test_file_name = "cube.obj";
    const test_file_contents = try readFile(io, gpa, test_file_name);
    defer gpa.free(test_file_contents);

    var model = try obj_parser_mod.parseObjFile(gpa, test_file_contents);
    defer model.deinit();
    std.log.debug("Parsed file\n{}", .{model});
    transformations.moveModelToOrigin(&model);
    std.log.debug("Moved:\n{}", .{model});

    var canvas = try Canvas.init(gpa, 16);
    defer canvas.deinit();

    var renderer: WireframeRenderer = .{};
    renderer.fitScale(&model);
    try renderer.render(&model, &canvas, io);
}

fn readFile(io: Io, allocator: std.mem.Allocator, file_name: []const u8) ![]const u8 {
    const cwd = Io.Dir.cwd();
    return try cwd.readFileAlloc(io, file_name, allocator, .unlimited);
}

comptime {
    _ = @import("obj_parser.zig");
    _ = @import("Canvas.zig");
}
