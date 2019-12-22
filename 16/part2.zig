const std = @import("std");

const input = @embedFile("input.txt") ** 10000;
const offset: usize = 5977377;
var in_arr: [input.len - offset]i64 = undefined;

fn lastDigit(x: i64) i64 {
    return std.math.absInt(@rem(x, 10)) catch unreachable;
}

fn fft(arr: []i64) void {
    var i: usize = arr.len;
    var accum: i64 = 0;
    while (i > 0) {
        i -= 1;
        accum += arr[i];
        arr[i] = lastDigit(accum);
    }
}

pub fn main() void {
    for (input[offset..]) |c, i| {
        in_arr[i] = c - '0';
    }

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        fft(&in_arr);
    }

    for (in_arr[0 .. 8]) |e| std.debug.warn("{}", .{e});
    std.debug.warn("\n", .{});
}
