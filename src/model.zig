const std = @import("std");

pub const Model = struct {
    verticies: []Vertex,
    faces: [][]const u32,
    allocator: std.mem.Allocator,

    pub fn deinit(self: Model) void {
        self.allocator.free(self.verticies);
        for (self.faces) |face| {
            self.allocator.free(face);
        }
        self.allocator.free(self.faces);
    }
};

pub const Vertex = @Vector(3, f32);
