const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

fn stepOnTheBeach(start_index: usize, n: usize) !usize {
    var index = start_index;

    var it = std.mem.separate(input, "\n");
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, "cut")) {
            const amount = try std.fmt.parseInt(i64, line["cut ".len ..], 10);
            const m = if (amount < 0) n - @intCast(usize, -amount) else @intCast(usize, amount);

            if (index < m) {
                index += n - m;
            } else {
                index -= m;
            }

        } else if (std.mem.startsWith(u8, line, "deal with increment")) {
            const increment = try std.fmt.parseInt(usize, line["deal with increment ".len ..], 10);
            // std.debug.warn("oef {}\n", .{increment});
            index = @mod(index * increment, n);
        } else if (std.mem.eql(u8, "deal into new stack", line)) {
            index = n - index - 1;
        } else {
            return error.InvalidOperation;
        }
    }

    return index;
}

pub fn main() !void {
    const n = 10007;
    var index: usize = 0;

    var period: usize = 0;
    while (true) {
        index = try stepOnTheBeach(index, n);
        // std.debug.warn("{}\n", .{index});

        if (index == 0) {
            break;
        }

        period += 1;
    }

    std.debug.warn("{}\n", .{period});

    // std.debug.warn("Final index of {}: {}\n", .{index, try stepOnTheBeach(index, n)});

    // var i: usize = 0;
    // while (i < n) : (i += 1) {
        // std.debug.warn("Final index of {}: {}\n", .{i, try stepOnTheBeach(i, n)});
    // }
}
