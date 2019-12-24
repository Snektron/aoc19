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
                var repr: u8 = '.';
                if (x == 2 and y == 2) {
                    repr = '?';
                } else if (self.get(x, y)) {
                    repr = '#';
                }

                std.debug.warn("{c}", .{repr});
            }

            std.debug.warn("\n", .{});
        }

        std.debug.warn("\n", .{});
    }

    fn countAlive(self: Grid) usize {
        var count: usize = 0;
        for (self.grid) |tile| {
            if (tile) {
                count += 1;
            }
        }

        return count;
    }
};

const RecursiveGrid = struct {
    levels: std.ArrayList(Grid),

    fn init(base: Grid) !RecursiveGrid {
        var levels = std.ArrayList(Grid).init(std.heap.page_allocator);
        try levels.resize(401);

        for (levels.toSlice()) |*level| {
            level.* = Grid.init();
        }

        levels.set(200, base);

        return RecursiveGrid{
            .levels = levels
        };
    }

    fn printAll(self: RecursiveGrid) void {
        for (self.levels.toSlice()) |level, i| {
            if (level.countAlive() > 0) {
                std.debug.warn("Depth {}:\n", .{@intCast(i64, i) - 200});
                level.print();
            }
        }
        std.debug.warn("---\n", .{});
    }

    fn evolve(self: *RecursiveGrid) !void {
        var next = try RecursiveGrid.init(Grid.init());
        var nextLevels = next.levels.toSlice();

        for (self.levels.toSlice()) |level, i| {
            var y: usize = 0;
            while (y < 5) : (y += 1) {
                var x: usize = 0;
                while (x < 5) : (x += 1) {
                    if ((x == 2 and y == 2) or i == 0 or i == self.levels.len - 1) {
                        continue;
                    }

                    const adjacent = self.countAdjacent(i, x, y);
                    if (level.get(x, y)) {
                        nextLevels[i].set(x, y, adjacent == 1);
                    } else {
                        nextLevels[i].set(x, y, adjacent == 1 or adjacent == 2);
                    }
                }
            }
        }

        self.levels.deinit();
        self.levels = next.levels;
    }

    fn countAdjacent(self: RecursiveGrid, level: usize, x: usize, y: usize) usize {
        std.debug.assert(!(x == 2 and y == 2));
        var count: usize = 0;

        // Test for (x - 1, y)
        if (x == 0) {
            if (self.levels.at(level + 1).get(1, 2)) count += 1;
            // std.debug.warn("x - 1: {} {} {}\n", .{level + 1, 1, 2});
        } else if (y == 2 and x == 3) {
            // Get values from one level down
            var i: usize = 0;
            while (i < 5) : (i += 1) {
                if (self.levels.at(level - 1).get(4, i)) count += 1;
                // std.debug.warn("x - 1: {} {} {}\n", .{level - 1, 4, i});
            }
        } else {
            if (self.levels.at(level).get(x - 1, y)) count += 1;
            // std.debug.warn("x - 1: {} {} {}\n", .{level, x - 1, y});
        }

        // (x + 1, y)
        if (x == 4) {
            if (self.levels.at(level + 1).get(3, 2)) count += 1;
            // std.debug.warn("x + 1: {} {} {}\n", .{level + 1, 3, 2});
        } else if (y == 2 and x == 1) {
            // Get values from one level down
            var i: usize = 0;
            while (i < 5) : (i += 1) {
                if (self.levels.at(level - 1).get(0, i)) count += 1;
                // std.debug.warn("x + 1: {} {} {}\n", .{level - 1, 0, i});
            }
        } else {
            if (self.levels.at(level).get(x + 1, y)) count += 1;
            // std.debug.warn("x + 1: {} {} {}\n", .{level, x + 1, y});
        }

        // (x, y - 1)
        if (y == 0) {
            if (self.levels.at(level + 1).get(2, 1)) count += 1;
            // std.debug.warn("y - 1: {} {} {}\n", .{level + 1, 2, 1});
        } else if (x == 2 and y == 3) {
            // Get values from one level down
            var i: usize = 0;
            while (i < 5) : (i += 1) {
                if (self.levels.at(level - 1).get(i, 4)) count += 1;
                // std.debug.warn("y - 1: {} {} {}\n", .{level - 1, i, 4});
            }
        } else {
            if (self.levels.at(level).get(x, y - 1)) count += 1;
            // std.debug.warn("y - 1: {} {} {}\n", .{level, x, y - 1});
        }

        // (x, y + 1)
        if (y == 4) {
            if (self.levels.at(level + 1).get(2, 3)) count += 1;
            // std.debug.warn("y + 1: {} {} {}\n", .{level + 1, 2, 3});
        } else if (x == 2 and y == 1) {
            // Get values from one level down
            var i: usize = 0;
            while (i < 5) : (i += 1) {
                if (self.levels.at(level - 1).get(i, 0)) count += 1;
                // std.debug.warn("y + 1: {} {} {}\n", .{level - 1, i, 0});
            }
        } else {
            if (self.levels.at(level).get(x, y + 1)) count += 1;
            // std.debug.warn("y + 1: {} {} {}\n", .{level, x, y + 1});
        }

        return count;
    }

    fn countAlive(self: RecursiveGrid) usize {
        var count: usize = 0;
        for (self.levels.toSlice()) |level| {
            count += level.countAlive();
        }

        return count;
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

    var rg = try RecursiveGrid.init(g);
    rg.printAll();
    var i: usize = 0;
    while (i < 200) : (i += 1) {
        try rg.evolve();
    }

    // rg.printAll();
    std.debug.warn("{}\n", .{rg.countAlive()});
}