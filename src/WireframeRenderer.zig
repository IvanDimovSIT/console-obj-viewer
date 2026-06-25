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
    const size = @max(-bb.max, bb.max) + @max(-bb.min, bb.min);

    self.scale = @max(size[0], size[1], size[2]);
}

pub fn render(self: Self, model: *const Model, canvas: *const Canvas, io: std.Io) !void {
    for (model.verticies) |v| {
        const point_x = 0.5 + v[0] / ((v[1] + self.scale) * self.scale);
        const point_y = 0.5 + v[2] / ((v[1] + self.scale) * self.scale);
        std.log.debug("Drawing x:{} y:{}", .{ point_x, point_y });
        canvas.drawPoint(point_x, point_y);
    }

    try canvas.display(io);
}
