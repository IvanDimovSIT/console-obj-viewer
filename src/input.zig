const std = @import("std");
const Io = std.Io;

pub fn readChar(io: Io) !u8 {
    var buf: [128]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(io, &buf);

    return (try stdin.interface.take(1))[0];
}
