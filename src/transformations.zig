const std = @import("std");
const model_mod = @import("model.zig");
const Model = model_mod.Model;
const Vertex = model_mod.Vertex;

pub const BoundingBox = struct { min: Vertex, max: Vertex };

pub fn moveModelToOrigin(model: *Model) void {
    const center = findCenter(model) orelse return;

    for (model.verticies) |*v| {
        v.* -= center;
    }
}

pub fn findBoundingBox(model: *const Model) ?BoundingBox {
    if (model.verticies.len == 0) {
        return null;
    }

    var min = model.verticies[0];
    var max = model.verticies[0];

    for (model.verticies[1..]) |v| {
        min = @min(min, v);
        max = @max(max, v);
    }

    return .{ .min = min, .max = max };
}

fn findCenter(model: *const Model) ?Vertex {
    const bb = findBoundingBox(model) orelse return null;
    return (bb.min + bb.max) * @as(Vertex, @splat(0.5));
}
