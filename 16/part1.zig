const std = @import("std");

const input = @embedFile("input.txt");

const PatternGenerator = struct {
    const base_pattern = [_]i64{0, 1, 0, -1};
    i: usize = 0,
    repeat: usize,

    fn init(repeat: usize) PatternGenerator {
        return .{
            .repeat = repeat
        };
    }

    fn skip(self: *PatternGenerator, n: usize) void {
        self.i += n;
    }

    fn next(self: *PatternGenerator) i64 {
        const index = @mod(@divFloor(self.i, self.repeat), PatternGenerator.base_pattern.len);
        const v = PatternGenerator.base_pattern[index];
        self.i += 1;
        return v;
    }
};

fn lastDigit(x: i64) i64 {
    return std.math.absInt(@rem(x, 10)) catch unreachable;
}

fn fft(arr: []i64) void {
    for (arr) |*elem, i| {
        var pg = PatternGenerator.init(i + 1);
        pg.skip(i + 1);

        var x: i64 = 0;
        for (arr[i..]) |y| {
            x += y * pg.next();
        }

        elem.* = lastDigit(x);
    }
}

pub fn main() void {
    var arr: [input.len]i64 = undefined;

    for (input) |c, i| {
        arr[i] = c - '0';
    }

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        fft(&arr);
    }

    for (arr[0..8]) |e| std.debug.warn("{}", .{e});
    std.debug.warn("\n", .{});
}
