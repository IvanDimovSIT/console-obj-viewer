const std = @import("std");
const Io = std.Io;
const transformations = @import("transformations.zig");
const input = @import("input.zig");
const Canvas = @import("Canvas.zig");
const WireframeRenderer = @import("WireframeRenderer.zig");
const model_mod = @import("model.zig");

const obj_parser_mod = @import("obj_parser.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    var iterator = try init.minimal.args.iterateAllocator(gpa);
    defer iterator.deinit();
    _ = iterator.next();
    const model_file_name = iterator.next() orelse {
        std.log.err("Command line arguments not found! Enter model name, width (optional) and height (optional)", .{});
        return;
    };
    const width = parseIntOrDefault(iterator.next(), 60, "error parsing display width");
    const height = parseIntOrDefault(iterator.next(), width / 2, "error parsing display height");

    const model_contents = try readFile(io, gpa, model_file_name);
    defer gpa.free(model_contents);

    var model = try obj_parser_mod.parseObjFile(gpa, model_contents);
    defer model.deinit();
    transformations.moveModelToOrigin(&model);

    var canvas = try Canvas.init(gpa, width, height);
    defer canvas.deinit();

    var renderer: WireframeRenderer = .{};
    renderer.fitScale(&model);
    try printModelInfo(io, model_file_name, &model);
    _ = try input.readChar(io);

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

fn parseIntOrDefault(str: ?[]const u8, default: u8, message: []const u8) u8 {
    if (str) |some_str| {
        return std.fmt.parseInt(u8, some_str, 10) catch |err| {
            std.log.err("{s}: {}", .{ message, err });
            return default;
        };
    } else {
        return default;
    }
}

fn printModelInfo(io: Io, model_name: []const u8, model: *const model_mod.Model) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    try stdout_writer.print("Loaded {s}\n", .{model_name});
    try stdout_writer.print("Verticies: {}\n", .{model.verticies.len});
    try stdout_writer.print("Faces: {}\n", .{model.faces.len});
    try stdout_writer.print("Controls:\n * Rotation: w s a d\n * Zoom: z x\n * Exit: e\n", .{});
    try stdout_writer.print("Press any key to display ...", .{});

    try stdout_writer.flush();
}
