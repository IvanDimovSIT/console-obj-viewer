const std = @import("std");
const model_mod = @import("model.zig");
const error_mod = @import("error.zig");
const Model = model_mod.Model;
const Vertex = model_mod.Vertex;
const ModelViewerError = error_mod.ModelViewerError;

const LineParseResult = union(enum) { none: void, vertex_result: Vertex, face_result: []const u32 };

/// returns Model allocated with the passed allocator
pub fn parseObjFile(allocator: std.mem.Allocator, file_contents: []const u8) !Model {
    var verticies = std.ArrayList(Vertex).empty;
    errdefer verticies.deinit(allocator);
    var faces = std.ArrayList([]const u32).empty;
    errdefer faces.deinit(allocator);
    var lines = std.mem.tokenizeScalar(u8, file_contents, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\n\t");
        const parse_result = try parseLine(allocator, trimmed);
        switch (parse_result) {
            .none => {},
            .vertex_result => |v| try verticies.append(allocator, v),
            .face_result => |f| try faces.append(allocator, f),
        }
    }

    return Model{ .verticies = try verticies.toOwnedSlice(allocator), .faces = try faces.toOwnedSlice(allocator) };
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) !LineParseResult {
    var parts = std.mem.tokenizeScalar(u8, line, ' ');

    const line_type_nullable = parts.next();
    if (line_type_nullable) |line_type| {
        if (line_type.len != 1) {
            return .none;
        }
        const line_symbol = line_type[0];

        return switch (line_symbol) {
            'v' => .{ .vertex_result = try parseVertex(&parts) },
            'f' => .{ .face_result = try parseFace(allocator, &parts) },
            else => .none,
        };
    } else {
        return .none;
    }
}

fn parseVertex(values: *std.mem.TokenIterator(u8, .scalar)) !Vertex {
    const x = try parseFloatForVertex(values);
    const y = try parseFloatForVertex(values);
    const z = try parseFloatForVertex(values);

    return .{ .x = x, .y = y, .z = z };
}

fn parseFloatForVertex(values: *std.mem.TokenIterator(u8, .scalar)) !f32 {
    if (values.next()) |str| {
        return std.fmt.parseFloat(f32, str) catch {
            return ModelViewerError.VertexParseError;
        };
    } else {
        return ModelViewerError.VertexParseError;
    }
}

fn parseFace(allocator: std.mem.Allocator, values: *std.mem.TokenIterator(u8, .scalar)) ![]const u32 {
    var indecies = std.ArrayList(u32).empty;
    errdefer indecies.deinit(allocator);
    try indecies.ensureTotalCapacity(allocator, 3);
    while (values.next()) |index_str| {
        const index = try parseFaceIndex(index_str);
        try indecies.append(allocator, index);
    }

    return try indecies.toOwnedSlice(allocator);
}

fn parseFaceIndex(str: []const u8) !u32 {
    var face_indecies = std.mem.tokenizeScalar(u8, str, '/');
    if (face_indecies.next()) |vertex_face_index| {
        return std.fmt.parseUnsigned(u32, vertex_face_index, 10) catch {
            return ModelViewerError.FaceParseError;
        };
    } else {
        return ModelViewerError.FaceParseError;
    }
}

test "parseObjFile" {
    const allocator = std.testing.allocator;
    const test_obj =
        \\# comment
        \\v 1.5 -2.5 0
        \\v 3.0 4.0 5.01
        \\v 4.0 5.0 6.0
        \\vn 100.0 200.0 300.0
        \\
        \\s off
        \\f 1/2 2/1 3/3
        \\
    ;

    var model = try parseObjFile(allocator, test_obj);
    defer model.deinit(allocator);
    const tolerance = 0.0001;

    try std.testing.expectEqual(@as(usize, 3), model.verticies.len);

    try std.testing.expectApproxEqAbs(@as(f32, 1.5), model.verticies[0].x, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, -2.5), model.verticies[0].y, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), model.verticies[0].z, tolerance);

    try std.testing.expectApproxEqAbs(@as(f32, 3.0), model.verticies[1].x, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), model.verticies[1].y, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 5.01), model.verticies[1].z, tolerance);

    try std.testing.expectApproxEqAbs(@as(f32, 4.0), model.verticies[2].x, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), model.verticies[2].y, tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), model.verticies[2].z, tolerance);

    try std.testing.expectEqual(@as(usize, 1), model.faces.len);
    try std.testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 3 }, model.faces[0]);
}
