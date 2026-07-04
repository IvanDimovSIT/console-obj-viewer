const std = @import("std");
const model_mod = @import("model.zig");
const transformations = @import("transformations.zig");

const Canvas = @import("Canvas.zig");
const Model = model_mod.Model;
const Vertex = model_mod.Vertex;
const Self = @This();

scale: f32 = 1.0,

pub fn fitScale(self: *Self, model: *const Model) void {
    const bb = transformations.findBoundingBox(model) orelse return;
    const size = @abs(bb.max) + @abs(bb.min);

    self.scale = @max(size[0], size[1], size[2]) * 1.6;
}

pub fn render(self: Self, model: *const Model, canvas: *const Canvas, io: std.Io) !void {
    canvas.clear();
    for (model.faces) |face| {
        self.renderFace(face, model.verticies, canvas);
    }

    try canvas.display(io);
}

fn renderFace(self: Self, face: []const u32, verticies: []const Vertex, canvas: *const Canvas) void {
    if (face.len <= 1) {
        return;
    }

    for (face[0..(face.len - 1)], face[1..]) |vertex_index1, vertex_index2| {
        const vertex1 = verticies[vertex_index1 - 1];
        const vertex2 = verticies[vertex_index2 - 1];
        self.drawEdge(vertex1, vertex2, canvas);
    }
    const vertex1 = verticies[face[0] - 1];
    const vertex2 = verticies[face[face.len - 1] - 1];
    self.drawEdge(vertex1, vertex2, canvas);
}

fn drawEdge(self: Self, start: Vertex, end: Vertex, canvas: *const Canvas) void {
    const start_x = 0.5 + start[0] / (self.scale - start[1]);
    const start_y = 0.5 + start[2] / (self.scale - start[1]);
    const end_x = 0.5 + end[0] / (self.scale - end[1]);
    const end_y = 0.5 + end[2] / (self.scale - end[1]);

    canvas.drawLine(start_x, start_y, end_x, end_y, '*');
    canvas.drawPoint(start_x, start_y, '*');
    canvas.drawPoint(end_x, end_y, '*');
}
