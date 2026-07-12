const std = @import("std");
const builtin = @import("builtin");

const Self = @This();

width: u8,
height: u8,
aspect_ratio: f32,
array: []u8,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator, width: u8, height: u8) !Self {
    if (width < 2 or height < 2) {
        return error.InvalidCanvasSize;
    }

    const width_f32: f32 = @floatFromInt(width);
    const height_f32: f32 = @floatFromInt(height);
    const console_character_aspect_ratio = 2.0;
    const aspect_ratio = console_character_aspect_ratio / (width_f32 / height_f32);
    const array = try allocator.alloc(u8, @as(usize, width) * @as(usize, height));
    @memset(array, ' ');

    return .{ .width = width, .height = height, .aspect_ratio = aspect_ratio, .allocator = allocator, .array = array };
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
    const start = self.coordinateToInts(x1, y1) orelse return;
    const end = self.coordinateToInts(x2, y2) orelse return;
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

    const line_char = determineLineChar(x, y, target_x, target_y);
    while (true) {
        std.debug.assert(x >= 0);
        std.debug.assert(y >= 0);
        const index = x + y * self.width;
        std.debug.assert(index >= 0);

        if (protected == null or self.array[@intCast(index)] != protected.?) {
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

fn determineLineChar(start_x: i32, start_y: i32, end_x: i32, end_y: i32) u8 {
    const sector_size = std.math.tau / 8.0;
    const dx: f32 = @floatFromInt(end_x - start_x);
    const dy: f32 = @floatFromInt(end_y - start_y);
    var angle = std.math.atan2(dy, dx);
    angle += sector_size / 2.0;
    while (angle > std.math.tau) {
        angle -= std.math.tau;
    }
    while (angle < 0) {
        angle += std.math.tau;
    }

    const sector = @floor(angle / sector_size);
    if (sector == 0.0 or sector == 4.0) {
        return '-';
    } else if (sector == 1.0 or sector == 5.0) {
        return '\\';
    } else if (sector == 2.0 or sector == 6.0) {
        return '|';
    } else if (sector == 3.0 or sector == 7.0) {
        return '/';
    }
    unreachable;
}

pub fn display(self: Self, io: std.Io) !void {
    clearScreen();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var row_n: u32 = 0;
    while (row_n < self.height) : (row_n += 1) {
        const start = row_n * @as(u32, self.width);
        const end = (row_n + 1) * @as(u32, self.width);
        const row = self.array[start..end];
        for (row, 0..) |char, index| {
            if (index + 1 < self.width) {
                try stdout_writer.print("{c}", .{char});
            } else {
                try stdout_writer.print("{c}\n", .{char});
            }
        }
    }

    try stdout_writer.flush();
}

extern "c" fn system([*]const c_char) c_int;
fn clearScreen() void {
    const command = if (builtin.target.os.tag == .windows) "cls" else if (builtin.target.os.tag == .linux) "clear" else return;
    _ = system(@ptrCast(command));
}

/// x and y must be between 0.0 and 1.0
fn coordinateToIndex(self: Self, x: f32, y: f32) ?u32 {
    const new_x = scalePointOneDimention(x, 0.5, self.aspect_ratio);
    if (new_x < 0.0 or new_x > 1.0 or y < 0.0 or y > 1.0) {
        return null;
    }
    const width_f32 = @as(f32, self.width - 1);
    const height_f32 = @as(f32, self.height - 1);
    const x_ind: u32 = @round(new_x * width_f32);
    const y_ind: u32 = @round(y * height_f32);

    return x_ind + y_ind * self.width;
}

fn coordinateToInts(self: Self, x: f32, y: f32) ?[2]u32 {
    const new_x = scalePointOneDimention(x, 0.5, self.aspect_ratio);
    if (new_x < 0.0 or new_x > 1.0 or y < 0.0 or y > 1.0) {
        return null;
    }
    const width_f32 = @as(f32, self.width - 1);
    const height_f32 = @as(f32, self.height - 1);
    const x_ind: u32 = @round(new_x * width_f32);
    const y_ind: u32 = @round(y * height_f32);

    return .{ x_ind, y_ind };
}

/// x - point to scale, o - origin
fn scalePointOneDimention(x: f32, o: f32, scale: f32) f32 {
    return o + scale * (x - o);
}

test "canvas" {
    const allocator = std.testing.allocator;
    var canvas = try Self.init(allocator, 2, 2);
    defer canvas.deinit();

    canvas.drawPoint(0.0, 0.0, '*');
    canvas.drawPoint(-100.0, 0.0, '*');
    canvas.drawPoint(0.0, -1000.0, '*');
    canvas.drawPoint(0.0, 1000.0, '*');
    canvas.drawPoint(2.0, 0.0, '*');
    canvas.drawPoint(1.0, 1.0, '*');

    try std.testing.expectEqualSlices(u8, canvas.array, "*  *");
}
