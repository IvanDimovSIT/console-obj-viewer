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

    pub fn dupe(self: *const Model) !Model {
        const verticies = try self.allocator.dupe(Vertex, self.verticies);
        const faces: [][]const u32 = try self.allocator.dupe([]const u32, self.faces);
        for (faces) |*face| {
            face.* = try self.allocator.dupe(u32, face.*);
        }

        return .{ .verticies = verticies, .faces = faces, .allocator = self.allocator };
    }
};

pub const Vertex = @Vector(3, f32);
