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
    var depths = [_]i64{-1} ** 65536;

    const com = idFromStr("COM");

    while (orbits.next()) |orbit| {
        const a = idFromStr(orbit[0 .. 3]);
        const b = idFromStr(orbit[4 .. 7]);

        parents[b] = a;
    }

    depths[com] = 0;
    var checksum: usize = 0;
    var object: u63 = 0;
    while (@intCast(usize, object) < parents.len) : (object += 1) {
        if (parents[object] == -1) {
            continue;
        }

        var x = parents[object];
        var depth: u63 = 0;

        while (x != -1) {
            depth += 1;

            if (depths[@intCast(u63, x)] != -1) {
                depth += @intCast(u63, depths[@intCast(u63, x)]);
                break;
            }

            x = parents[@intCast(u63, x)];
        }

        depths[object] = depth;
        checksum += depth;
    }

    std.debug.warn("Time: {}us\n", timer.read() / 1000);
    std.debug.warn("Checksum: {}\n", checksum);
}
