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
pub fn drawPoint(self: Self, x: f32, y: f32, char: u8) void {
    const index = self.coordinateToIndex(x, y) orelse return;
    self.array[index] = char;
}

/// coordinates must be between 0.0 and 1.0, protected symbol will not be drawn over
pub fn drawLine(self: Self, x1: f32, y1: f32, x2: f32, y2: f32, protected: ?u8) void {
    const start = self.coordinateToInts(std.math.clamp(x1, 0.0, 1.0), std.math.clamp(y1, 0.0, 1.0)) orelse return;
    const end = self.coordinateToInts(std.math.clamp(x2, 0.0, 1.0), std.math.clamp(y2, 0.0, 1.0)) orelse return;
    var x: i32 = @intCast(start[0]);
    var y: i32 = @intCast(start[1]);
    var prev_x: i32 = x;
    var prev_y: i32 = y;

    const target_x: i32 = @intCast(end[0]);
    const target_y: i32 = @intCast(end[1]);

    const dx: i32 = @intCast(@abs(target_x - x));
    const sx: i32 = if (x < target_x) 1 else -1;

    var dy: i32 = @intCast(@abs(target_y - y));
    dy = -dy;
    const sy: i32 = if (y < target_y) 1 else -1;

    var err = dx + dy;

    while (true) {
        std.debug.assert(x >= 0);
        std.debug.assert(y >= 0);
        const index = x + y * self.size;
        std.debug.assert(index >= 0);
        std.debug.assert(index < @as(i32, self.size) * @as(i32, self.size));
        if (protected == null or self.array[@intCast(index)] != protected.?) {
            const line_char = determineLineChar(prev_x, prev_y, x, y);
            self.array[@intCast(index)] = line_char;
        }

        prev_x = x;
        prev_y = y;
        if (x == target_x and y == target_y) {
            break;
        }

        const e2 = 2 * err;

        if (e2 >= dy) {
            err += dy;
            x += sx;
        }

        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

fn determineLineChar(prev_x: i32, prev_y: i32, x: i32, y: i32) u8 {
    if (prev_x == x and prev_y != y) {
        return '|';
    } else if (prev_x != x and prev_y == y) {
        return '-';
    } else if ((prev_x < x and prev_y > y) or (x < prev_x and y > prev_y)) {
        return '/';
    } else {
        return '\\';
    }
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

fn coordinateToInts(self: Self, x: f32, y: f32) ?[2]u32 {
    if (x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0) {
        return null;
    }
    const size_f32 = @as(f32, self.size - 1);
    const x_ind: u32 = @round(x * size_f32);
    const y_ind: u32 = @round(y * size_f32);

    return .{ x_ind, y_ind };
}

test "canvas" {
    const allocator = std.testing.allocator;
    var canvas = try Self.init(allocator, 2);
    defer canvas.deinit();

    canvas.drawPoint(0.0, 0.0, '*');
    canvas.drawPoint(-100.0, 0.0, '*');
    canvas.drawPoint(0.0, -1000.0, '*');
    canvas.drawPoint(0.0, 1000.0, '*');
    canvas.drawPoint(2.0, 0.0, '*');
    canvas.drawPoint(1.0, 1.0, '*');

    try std.testing.expectEqualSlices(u8, canvas.array, "*  *");
}
