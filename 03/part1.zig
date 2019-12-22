const std = @import("std");
const input = @embedFile("input.txt");

pub fn main() !void {
    const dim: usize = (1 << 13) + (1 << 14);
    const board = try std.heap.page_allocator.alloc(u8, dim * dim);
    std.mem.set(u8, board, 0);

    var it = std.mem.separate(input, "\n");
    var line: u8 = 1;

    var min_dst: isize = 9999999;

    while (it.next()) |part| {
        var seg_it = std.mem.separate(part, ",");
        var x: usize = 16384;
        var y: usize = 16384;

        while (seg_it.next()) |segment| {
            const dir = segment[0];
            var amount = try std.fmt.parseInt(u64, segment[1 ..], 10);

            while (amount > 0) {
                if (line == 2 and board[dim * x + y] == 1) {
                    const dst = (std.math.absInt(@intCast(isize, x) - 16384) catch unreachable) + (std.math.absInt(@intCast(isize, y) - 16384) catch unreachable);

                    if (dst > 0 and dst < min_dst) {
                        min_dst = dst;
                    }
                }

                board[dim * x + y] = line;

                switch (dir) {
                    'U' => y += 1,
                    'D' => y -= 1,
                    'R' => x += 1,
                    'L' => x -= 1,
                    else => return error.InvalidDirection
                }

                amount -= 1;
            }

            if (line == 2 and board[dim * x + y] == 1) {
                std.debug.warn("{} {}\n", x, y);
            }
            board[dim * x + y] = line;
        }

        line += 1;
    }

    std.debug.warn("{}\n", min_dst);
}
