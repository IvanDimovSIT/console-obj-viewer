const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

extern "c" fn _getch() c_int;

pub fn readChar(io: Io) !u8 {
    if (builtin.target.os.tag == .windows) {
        const char = _getch();
        return @intCast(char);
    } else {
        var buf: [128]u8 = undefined;
        var stdin = std.Io.File.stdin().reader(io, &buf);
        return (try stdin.interface.take(1))[0];
    }
}
