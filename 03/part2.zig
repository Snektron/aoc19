const std = @import("std");
const input = @embedFile("input.txt");

const Tile = struct {
    line_1_time: u32,
    line: u8
};

pub fn main() !void {
    const dim: usize = (1 << 13) + (1 << 14);
    const board = try std.heap.page_allocator.alloc(Tile, dim * dim);
    std.mem.set(Tile, board, Tile {
        .line_1_time = 0,
        .line = 0
    });

    var it = std.mem.separate(input, "\n");
    var line: u8 = 1;

    var min_steps: usize = 9999999;

    while (it.next()) |part| {
        var seg_it = std.mem.separate(part, ",");
        var x: usize = 16384;
        var y: usize = 16384;
        var time: u32 = 0;

        while (seg_it.next()) |segment| {
            const dir = segment[0];
            var amount = try std.fmt.parseInt(u64, segment[1 ..], 10);

            while (amount > 0) {

                if (line == 2 and board[dim * x + y].line == 1) {
                    const steps = time + board[dim * x + y].line_1_time;

                    if (steps > 0 and steps < min_steps) {
                        min_steps = steps;
                    }
                }

                if (line == 1 and board[dim * x + y].line == 0) {
                    board[dim * x + y].line_1_time = time;
                }

                board[dim * x + y].line = line;

                switch (dir) {
                    'U' => y += 1,
                    'D' => y -= 1,
                    'R' => x += 1,
                    'L' => x -= 1,
                    else => return error.InvalidDirection
                }

                time += 1;
                amount -= 1;
            }
        }

        line += 1;
    }

    std.debug.warn("{}\n", min_steps);
}
