const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

fn dealIntoNewStack(arr: []i64) void {
    std.mem.reverse(i64, arr);
}

fn cut(arr: []i64, n: i64) void {
    var tmp: [10007]i64 = undefined;

    const m = if (n < 0) arr.len - @intCast(usize, -n) else @intCast(usize, n);

    var i: usize = 0;
    while (i < arr.len - m) : (i += 1) {
        tmp[i] = arr[i + m];
    }

    while (i < arr.len) : (i += 1) {
        tmp[i] = arr[i - (arr.len - m)];
    }

    std.mem.copy(i64, arr, tmp[0 .. arr.len]);
}

fn deal(arr: []i64, incr: usize) void {
    var tmp: [10007]i64 = undefined;
    var i: usize = 0;
    var j: usize = 0;

    while (i < arr.len) {
        tmp[@mod(j, arr.len)] = arr[i];
        j += incr;
        i += 1;
    }

    std.mem.copy(i64, arr, tmp[0 .. arr.len]);
}

fn dump(a: []i64) void {
    for (a) |x| {
        std.debug.warn("{} ", .{x});
    }

    std.debug.warn("\n", .{});
}

pub fn main() !void {
    const n = 10007;
    var deck: [n]i64 = undefined;

    var i: usize = 0;
    while (i < n) : (i += 1) {
        deck[i] = @intCast(i64, i);
    }

    var it = std.mem.separate(input, "\n");
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, "cut")) {
            cut(&deck, try std.fmt.parseInt(i64, line["cut ".len ..], 10));
        } else if (std.mem.startsWith(u8, line, "deal with increment")) {
            deal(&deck, try std.fmt.parseInt(usize, line["deal with increment ".len ..], 10));
        } else if (std.mem.eql(u8, "deal into new stack", line)) {
            dealIntoNewStack(&deck);
        } else {
            return error.InvalidOperation;
        }
    }

    for (deck) |card, k| {
        if (card == 2019) {
            std.debug.warn("{}\n", .{k});
        }
    }
}
