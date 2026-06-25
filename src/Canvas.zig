const std = @import("std");
const Self = @This();

size: u8,
array: []u8,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, size: u8) !Self {
    if (size < 2) {
        return error.InvalidCanvasSize;
    }

    const array = try allocator.alloc(u8, @as(usize, size) * @as(usize, size));
    @memset(array, ' ');

    return .{ .size = size, .allocator = allocator, .array = array };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.array);
}

pub fn clear(self: Self) void {
    @memset(self.array, ' ');
}

/// x and y must be between 0.0 and 1.0
pub fn drawPoint(self: Self, x: f32, y: f32) void {
    const index = self.coordinateToIndex(x, y) orelse return;
    self.array[index] = '*';
}

pub fn display(self: Self, io: std.Io) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var row_n: u32 = 0;
    while (row_n < self.size) : (row_n += 1) {
        const start = row_n * @as(u32, self.size);
        const end = (row_n + 1) * @as(u32, self.size);
        const row = self.array[start..end];
        for (row, 0..) |char, index| {
            if (index + 1 < self.size) {
                try stdout_writer.print("{c} ", .{char});
            } else {
                try stdout_writer.print("{c}\n", .{char});
            }
        }
    }

    try stdout_writer.flush();
}

/// x and y must be between 0.0 and 1.0
fn coordinateToIndex(self: Self, x: f32, y: f32) ?u32 {
    if (x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0) {
        return null;
    }
    const size_f32 = @as(f32, self.size - 1);
    const x_ind: u32 = @round(x * size_f32);
    const y_ind: u32 = @round(y * size_f32);

    return x_ind + y_ind * self.size;
}

test "canvas" {
    const allocator = std.testing.allocator;
    var canvas = try Self.init(allocator, 2);
    defer canvas.deinit();

    canvas.drawPoint(0.0, 0.0);
    canvas.drawPoint(-100.0, 0.0);
    canvas.drawPoint(0.0, -1000.0);
    canvas.drawPoint(0.0, 1000.0);
    canvas.drawPoint(2.0, 0.0);
    canvas.drawPoint(1.0, 1.0);

    try std.testing.expectEqualSlices(u8, canvas.array, "*  *");
}
