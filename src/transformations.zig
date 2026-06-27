const std = @import("std");
const model_mod = @import("model.zig");
const Model = model_mod.Model;
const Vertex = model_mod.Vertex;

pub const BoundingBox = struct { min: Vertex, max: Vertex };

pub fn rotateModelAroundOrigin(model: *Model, x_rad: f32, y_rad: f32, z_rad: f32) void {
    if (x_rad != 0.0) {
        rotateAroundX(model, x_rad);
    }
    if (y_rad != 0.0) {
        rotateAroundY(model, y_rad);
    }
    if (z_rad != 0.0) {
        rotateAroundZ(model, z_rad);
    }
}

fn rotateAroundX(model: *Model, x_rad: f32) void {
    const x_sin = @sin(x_rad);
    const x_cos = @cos(x_rad);

    for (model.verticies) |*v| {
        const y = v[1];
        const z = v[2];

        v[1] = y * x_cos - z * x_sin;
        v[2] = y * x_sin + z * x_cos;
    }
}

fn rotateAroundY(model: *Model, y_rad: f32) void {
    const y_sin = @sin(y_rad);
    const y_cos = @cos(y_rad);

    for (model.verticies) |*v| {
        const x = v[0];
        const z = v[2];

        v[0] = x * y_cos + z * y_sin;
        v[2] = -x * y_sin + z * y_cos;
    }
}

fn rotateAroundZ(model: *Model, z_rad: f32) void {
    const z_sin = @sin(z_rad);
    const z_cos = @cos(z_rad);

    for (model.verticies) |*v| {
        const x = v[0];
        const y = v[1];

        v[0] = x * z_cos - y * z_sin;
        v[1] = x * z_sin + y * z_cos;
    }
}

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
