const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T
    };
}

const Direction = enum {
    North,
    East,
    South,
    West,

    fn opposite(self: Direction) Direction {
        return @intToEnum(Direction, @enumToInt(self) +% 2);
    }

    fn cw(self: Direction) Direction {
        return @intToEnum(Direction, @enumToInt(self) +% 1);
    }

    fn ccw(self: Direction) Direction {
        return @intToEnum(Direction, @enumToInt(self) +% 3);
    }

    fn offset(self: Direction) Vec2(i64) {
        return switch (self) {
            .North => .{.x = 0, .y = -1},
            .East => .{.x = 1, .y = 0},
            .South => .{.x = 0, .y = 1},
            .West => .{.x = -1, .y = 0},
        };
    }
};

const Tile = union(enum) {
    Empty,
    Passage,
    Wall,
    Portal: [2]u8
};

fn alphabetic(x: u8) bool {
    return x >= 'A' and x <= 'Z';
}

const Map = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(Tile),

    fn init(width: usize, height: usize) !Map {
        var data = std.ArrayList(Tile).init(std.heap.page_allocator);
        try data.resize(width * height);

        for (data.toSlice()) |*i| i.* = .Empty;

        return Map {
            .width = width,
            .height = height,
            .data = data
        };
    }

    fn deinit(self: *Map) void {
        self.data.deinit();
    }

    fn draw(self: *Map) void {
        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                const repr: u8 = switch (self.get(x, y)) {
                    .Empty => ' ',
                    .Passage => '.',
                    .Wall => '#',
                    .Portal => '@',
                };

                std.debug.warn("{c}", .{repr});
            }

            std.debug.warn("\n", .{});
        }
    }

    fn index(self: *Map, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn get(self: *Map, x: usize, y: usize) Tile {
        return self.data.toSlice()[self.index(x, y)];
    }

    fn set(self: *Map, x: usize, y: usize, value: Tile) void {
        self.data.toSlice()[self.index(x, y)] = value;
    }

    fn getTargetGate(self: *Map, x: usize, y: usize) ?Vec2(usize) {
        const name = self.get(x, y).Portal;

        var y1: usize = 0;
        while (y1 < self.height) : (y1 += 1) {
            var x1: usize = 0;
            while (x1 < self.width) : (x1 += 1) {
                if (self.get(x1, y1) == .Portal and (x1 != x or y1 != y)) {
                    const tname = self.get(x1, y1).Portal;
                    if (tname[0] == name[0] and tname[1] == name[1]) {
                        return Vec2(usize){.x = x1, .y = y1};
                    }
                }
            }
        }

        return null;
    }

    fn findGate(self: *Map, name: *const [2]u8) ?Vec2(usize) {
        var y1: usize = 0;
        while (y1 < self.height) : (y1 += 1) {
            var x1: usize = 0;
            while (x1 < self.width) : (x1 += 1) {
                if (self.get(x1, y1) == .Portal) {
                    const tname = self.get(x1, y1).Portal;
                    if (tname[0] == name[0] and tname[1] == name[1]) {
                        return Vec2(usize){.x = x1, .y = y1};
                    }
                }
            }
        }

        return null;
    }

    fn findEntry(self: *Map, x: usize, y: usize) Vec2(usize) {
        if (x > 0 and self.get(x - 1, y) == .Passage) {
            return Vec2(usize){.x = x - 1, .y = y};
        } else if (y > 0 and self.get(x, y - 1) == .Passage) {
            return Vec2(usize){.x = x, .y = y - 1};
        } else if (x < self.width - 1 and self.get(x + 1, y) == .Passage) {
            return Vec2(usize){.x = x + 1, .y = y};
        } else if (y < self.height - 1 and self.get(x, y + 1) == .Passage) {
            return Vec2(usize){.x = x, .y = y + 1};
        }

        unreachable;
    }

    fn move(self: *Map, x: usize, y: usize, dir: Direction) ?Vec2(usize) {
        const offs = dir.offset();
        const newx = @intCast(usize, @intCast(i64, x) + offs.x);
        const newy = @intCast(usize, @intCast(i64, y) + offs.y);

        if (self.get(newx, newy) == .Passage) {
            return Vec2(usize){.x = newx, .y = newy};
        } else if (self.get(newx, newy) != .Portal) {
            return null;
        } else if (self.getTargetGate(newx, newy)) |target| {
            return self.findEntry(target.x, target.y);
        }

        std.debug.warn("{}\n", .{self.get(newx, newy)});
        unreachable;
    }

    fn aaToZz(self: *Map) !usize {
        var seen = std.ArrayList(bool).init(std.heap.page_allocator);
        try seen.resize(self.width * self.height);
        for (seen.toSlice()) |*i| i.* = false;

        const Candidate = struct {
            const Self = @This();

            x: usize,
            y: usize,
            path_length: usize,

            fn compare(a: Self, b: Self) bool {
                return a.path_length < b.path_length;
            }
        };

        var pq = std.PriorityQueue(Candidate).init(std.heap.page_allocator, Candidate.compare);
        defer pq.deinit();

        const start_gate = self.findGate("AA").?;
        const begin = self.findEntry(start_gate.x, start_gate.y);
        try pq.add(.{.x = begin.x, .y = begin.y, .path_length = 0});
        seen.toSlice()[self.index(start_gate.x, start_gate.y)] = true;
        seen.toSlice()[self.index(begin.x, begin.y)] = true;

        while (pq.count() > 0) {
            const candidate = pq.remove();
            for ([_]Direction{.North, .West, .South, .East}) |dir| {
                const offs = dir.offset();
                const newx = @intCast(usize, @intCast(i64, candidate.x) + offs.x);
                const newy = @intCast(usize, @intCast(i64, candidate.y) + offs.y);
                const move_tile = self.get(newx, newy);

                if (seen.toSlice()[self.index(newx, newy)]) {
                    continue;
                }

                if (move_tile == .Portal and move_tile.Portal[0] == 'Z' and move_tile.Portal[1] == 'Z') {
                    return candidate.path_length;
                }

                if (self.move(candidate.x, candidate.y, dir)) |t| {
                    if (!seen.toSlice()[self.index(t.x, t.y)]) {
                        seen.toSlice()[self.index(t.x, t.y)] = true;
                        seen.toSlice()[self.index(newx, newy)] = true;
                        try pq.add(.{.x = t.x, .y = t.y, .path_length = candidate.path_length + 1});
                    }
                }
            }
        }

        unreachable;
    }

    fn simplify(self: *Map) bool {
        var anychanged = false;

        var y: usize = 1;
        while (y < self.height - 1) : (y += 1) {
            var x: usize = 1;
            while (x < self.width - 1) : (x += 1) {
                if (self.get(x, y) != .Passage) {
                    continue;
                }

                var n: usize = 0;
                if (self.get(x + 1, y) == .Wall) {
                    n += 1;
                }

                if (self.get(x - 1, y) == .Wall) {
                    n += 1;
                }

                if (self.get(x, y + 1) == .Wall) {
                    n += 1;
                }

                if (self.get(x, y - 1) == .Wall) {
                    n += 1;
                }

                if (n >= 3) {
                    self.set(x, y, .Wall);
                    anychanged = true;
                }
            }
        }

        return anychanged;
    }
};

fn insertVerticalPortals(map: *Map, y: usize, a: []const u8, b: []const u8, x: ?[]const u8) void {
    for (a) |c, i| {
        if (i < b.len and alphabetic(c) and alphabetic(b[i])) {
            if (x) |z| {
                if (z[i] == ' ') {
                    map.set(i - 1, y, Tile{.Portal = .{c, b[i]}});
                } else {
                    map.set(i - 1, y - 1, Tile{.Portal = .{c, b[i]}});
                }
            } else {
                map.set(i - 1, y, Tile{.Portal = .{c, b[i]}});
            }
        }
    }
}

fn insertHorizontalPortals(map: *Map, y: usize, line: []const u8) void {
    for (line[0 .. line.len - 1]) |c, i| {
        if (alphabetic(c) and alphabetic(line[i + 1])) {
            if (i + 2 >= line.len or line[i + 2] == ' ') {
                map.set(i - 1, y, Tile{.Portal = .{line[i], line[i + 1]}});
            } else {
                map.set(i, y, Tile{.Portal = .{line[i], line[i + 1]}});
            }
        }
    }
}

pub fn main() !void {
    var height: usize = 0;
    var width: usize = 0;

    {
        var lines = std.mem.separate(input, "\n");
        while (lines.next()) |line| {
            height += 1;
            // width = std.math.max(line.len, width);
            // width = std.math.max(line.len, width);
            if (std.mem.lastIndexOf(u8, line, "#")) |pos| {
                width = std.math.max(width, pos + 3);
            }
        }
    }

    var map = try Map.init(width - 2, height - 2);
    defer map.deinit();

    {
        var it = std.mem.separate(input, "\n");

        const first_line: []const u8 = it.next().?;
        var last_line: []const u8 = it.next().?;
        var last_line_2: ?[]const u8 = null;
        insertVerticalPortals(&map, 0, first_line, last_line, null);

        var j: usize = 2;
        while (it.next()) |line| {
            if (j >= height - 2) {
                insertVerticalPortals(&map, j - 1, line, it.next().?, null);
                break;
            }

            for (line[2 .. width - 2]) |c, i| {
                const tile: Tile = switch (c) {
                    ' ' => .Empty,
                    '#' => .Wall,
                    '.' => .Passage,
                    else => continue
                };

                map.set(i + 1, j - 1, tile);
            }

            insertHorizontalPortals(&map, j - 1, line);
            insertVerticalPortals(&map, j - 1, last_line, line, last_line_2);

            j += 1;
            last_line_2 = last_line;
            last_line = line;
        }
    }

    while (map.simplify()) {
        continue;
    }

    map.draw();
    std.debug.warn("{}\n", .{try map.aaToZz()});
}
