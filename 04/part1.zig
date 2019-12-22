const std = @import("std");

pub fn main() !void {
    var i: usize = 153517;
    var buf: [6]u8 = undefined;
    var candidates: usize = 0;

    outer: while (i < 630395) : (i += 1) {
        const int = try std.fmt.bufPrint(&buf, "{}", i);

        var j: usize = 1;
        var duplicate: usize = 0;

        while (j < int.len) : (j += 1) {
            if (int[j - 1] > int[j]) {
                continue :outer;
            } else if (int[j - 1] == int[j]) {
                duplicate += 1;
            }
        }

        if (duplicate == 0) {
            continue;
        }

        candidates += 1;
    }

    std.debug.warn("{}\n", candidates);
}
