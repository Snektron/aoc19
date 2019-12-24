const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Grid = struct {
    grid: [5 * 5]bool,

    fn init() Grid {
        return .{
            .grid = [_]bool{false} ** 25
        };
    }

    fn index(x: usize, y: usize) usize {
        return y * 5 + x;
    }

    fn get(self: Grid, x: usize, y: usize) bool {
        return self.grid[Grid.index(x, y)];
    }

    fn set(self: *Grid, x: usize, y: usize, state: bool) void {
        self.grid[Grid.index(x, y)] = state;
    }

    fn print(self: Grid) void {
        var y: usize = 0;
        while (y < 5) : (y += 1) {
            var x: usize = 0;
            while (x < 5) : (x += 1) {
                const repr: u8 = if (self.get(x, y)) '#' else '.';
                std.debug.warn("{c}", .{repr});
            }

            std.debug.warn("\n", .{});
        }

        std.debug.warn("\n", .{});
    }

    fn countAdjacent(self: Grid, x: usize, y: usize) usize {
        var count: usize = 0;
        if (x > 0 and self.get(x - 1, y)) count += 1;
        if (x < 4 and self.get(x + 1, y)) count += 1;
        if (y > 0 and self.get(x, y - 1)) count += 1;
        if (y < 4 and self.get(x, y + 1)) count += 1;
        return count;
    }

    fn evolve(self: *Grid) void {
        var next = Grid.init();

        var y: usize = 0;
        while (y < 5) : (y += 1) {
            var x: usize = 0;
            while (x < 5) : (x += 1) {
                const adjacent = self.countAdjacent(x, y);
                if (self.get(x, y)) {
                    next.set(x, y, adjacent == 1);
                } else {
                    next.set(x, y, adjacent == 1 or adjacent == 2);
                }
            }
        }

        self.grid = next.grid;
    }

    fn rating(self: Grid) u25 {
        var value: u25 = 0;
        var y: usize = 0;
        while (y < 5) : (y += 1) {
            var x: usize = 0;
            while (x < 5) : (x += 1) {
                if (self.get(x, y)) {
                    value += @as(u25, 1) << @intCast(u5, Grid.index(x, y));
                }
            }
        }

        return value;
    }
};

pub fn main() !void {
    var g = Grid.init();

    {
        var lines = std.mem.separate(input, "\n");
        var i: usize = 0;
        while (lines.next()) |line| {
            for (line) |c, j| {
                if (c == '#') {
                    g.set(j, i, true);
                }
            }

            i += 1;
        }
    }

    var seen = std.AutoHashMap(u25, void).init(std.heap.page_allocator);
    _ = try seen.put(g.rating(), .{});

    g.print();
    while (true) {
        g.evolve();
        if (try seen.put(g.rating(), .{})) |_| {
            break;
        }
    }

    std.debug.warn("First double:\n", .{});
    g.print();
    std.debug.warn("Rating: {}\n", .{g.rating()});
}