const std = @import("std");

pub const Model = struct {
    verticies: []Vertex,
    faces: [][]const u32,

    pub fn deinit(self: Model, allocator: std.mem.Allocator) void {
        allocator.free(self.verticies);
        for (self.faces) |face| {
            allocator.free(face);
        }
        allocator.free(self.faces);
    }
};

pub const Vertex = struct { x: f32, y: f32, z: f32 };
