const std = @import("std");
const input = @embedFile("input.txt");

fn mapChar(char: u8) u63 {
    if ('0' <= char and char <= '9') {
        return char - '0' + 26;
    } else {
        return char - 'A';
    }
}

fn idFromStr(str: []const u8) u63 {
    return (mapChar(str[0]) * 36 + mapChar(str[1])) * 36 + mapChar(str[2]);
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    var orbits = std.mem.separate(input, "\n");

    var parents = [_]i64{-1} ** 65536;
    var transfers_to_santa_needed = [_]i64{-1} ** 63356;

    const com = idFromStr("COM");
    const you = idFromStr("YOU");
    const san = idFromStr("SAN");

    var direct: usize = 0;
    while (orbits.next()) |orbit| {
        const a = idFromStr(orbit[0 .. 3]);
        const b = idFromStr(orbit[4 .. 7]);

        parents[b] = a;
    }

    var x = parents[san];
    var transfers_needed: i64 = 0;

    while (x != -1) {
        transfers_to_santa_needed[@intCast(u63, x)] = transfers_needed;
        transfers_needed += 1;
        x = parents[@intCast(u63, x)];
    }

    x = parents[you];
    transfers_needed = 0;

    while (x != -1) {
        if (transfers_to_santa_needed[@intCast(u63, x)] != -1) {
            std.debug.warn("{}\n", transfers_to_santa_needed[@intCast(u63, x)] + transfers_needed);
            break;
        }

        transfers_needed += 1;
        x = parents[@intCast(u63, x)];
    }

    std.debug.warn("Time: {}us\n", timer.read() / 1000);
}
