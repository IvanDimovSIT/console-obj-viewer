const std = @import("std");
const Io = std.Io;
const transformations = @import("transformations.zig");
const input = @import("input.zig");
const Canvas = @import("Canvas.zig");
const WireframeRenderer = @import("WireframeRenderer.zig");

const obj_parser_mod = @import("obj_parser.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    var iterator = try init.minimal.args.iterateAllocator(gpa);
    defer iterator.deinit();
    _ = iterator.next();
    const model_file_name = iterator.next() orelse {
        std.log.err("File name not entered", .{});
        return;
    };
    const model_contents = try readFile(io, gpa, model_file_name);
    defer gpa.free(model_contents);

    var model = try obj_parser_mod.parseObjFile(gpa, model_contents);
    defer model.deinit();
    transformations.moveModelToOrigin(&model);

    var canvas = try Canvas.init(gpa, 50);
    defer canvas.deinit();

    var renderer: WireframeRenderer = .{};
    renderer.fitScale(&model);

    while (true) {
        const rotation_amount = std.math.pi * 0.02;
        try renderer.render(&model, &canvas, io);

        const char = try input.readChar(io);
        if (char == 'e') {
            break;
        }
        switch (char) {
            'd' => transformations.rotateModelAroundOrigin(&model, 0.0, 0.0, rotation_amount),
            'a' => transformations.rotateModelAroundOrigin(&model, 0.0, 0.0, -rotation_amount),
            's' => transformations.rotateModelAroundOrigin(&model, rotation_amount, 0.0, 0.0),
            'w' => transformations.rotateModelAroundOrigin(&model, -rotation_amount, 0.0, 0.0),
            'z' => renderer.scale *= 1.02,
            'x' => renderer.scale *= 0.98,
            else => {},
        }
    }
}

/// returns heap allocated file contents with allocator
fn readFile(io: Io, allocator: std.mem.Allocator, file_name: []const u8) ![]const u8 {
    const cwd = Io.Dir.cwd();
    return try cwd.readFileAlloc(io, file_name, allocator, .unlimited);
}
