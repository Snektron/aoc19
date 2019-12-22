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

const PortalType = enum {
    Inner,
    Outer
};

const Portal = struct {
    name: [2]u8,
    ty: PortalType
};

const Tile = union(enum) {
    Empty,
    Passage,
    Wall,
    Portal: Portal,

    fn portal(name: [2]u8, ty: PortalType) Tile {
        return Tile{.Portal = .{.name = name, .ty = ty}};
    }

    fn isPortal(self: Tile, name: [2]u8) bool {
        return self == .Portal and self.Portal.name[0] == name[0] and self.Portal.name[1] == name[1];
    }
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
                    .Portal => |p| if (p.ty == .Inner) @as(u8, '@') else @as(u8, '*'),
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
        const name = self.get(x, y).Portal.name;

        var y1: usize = 0;
        while (y1 < self.height) : (y1 += 1) {
            var x1: usize = 0;
            while (x1 < self.width) : (x1 += 1) {
                if (self.get(x1, y1) == .Portal and (x1 != x or y1 != y)) {
                    const tname = self.get(x1, y1).Portal.name;
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
                    const tname = self.get(x1, y1).Portal.name;
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

    fn resolvePortal(self: *Map, x: usize, y: usize) ?Vec2(usize) {
        const target = self.getTargetGate(newx, newy).?;
        return self.findEntry(target.x, target.y);
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

    fn aaToZzRecursive(self: *Map) !usize {
        const Candidate = struct {
            const Self = @This();

            x: usize,
            y: usize,
            path_length: usize,
            depth: usize,
            lastx: usize,
            lasty: usize,

            fn compare(a: Self, b: Self) bool {
                return a.path_length < b.path_length;
            }
        };

        var pq = std.PriorityQueue(Candidate).init(std.heap.page_allocator, Candidate.compare);
        defer pq.deinit();

        const start_gate = self.findGate("AA").?;
        const begin = self.findEntry(start_gate.x, start_gate.y);
        try pq.add(.{
            .x = begin.x,
            .y = begin.y,
            .path_length = 0,
            .depth = 0,
            .lastx = start_gate.x,
            .lasty = start_gate.y
        });

        var i: usize = 0;

        while (pq.count() > 0) {
            i += 1;

            const candidate = pq.remove();
            for ([_]Direction{.North, .West, .South, .East}) |dir| {
                const offs = dir.offset();
                const newx = @intCast(usize, @intCast(i64, candidate.x) + offs.x);
                const newy = @intCast(usize, @intCast(i64, candidate.y) + offs.y);
                const move_tile = self.get(newx, newy);
                var depth = candidate.depth;

                if (move_tile.isPortal("ZZ".*)) {
                    if (depth == 0) {
                        return candidate.path_length;
                    } else {
                        continue;
                    }
                } else if (move_tile.isPortal("AA".*)) {
                    continue;
                }

                if (move_tile == .Portal) {
                    const movement = if (move_tile.Portal.ty == .Inner) "down" else "up";

                    if (move_tile.Portal.ty == .Inner) {
                        // Move down the stack
                        depth += 1;
                    } else {
                        // Move up the stack
                        if (depth == 0) {
                            continue;
                        }

                        depth -= 1;
                    }

                    // std.debug.warn("Portalling {} through {} (depth {}, path {})\n", .{movement, move_tile.Portal.name, depth, candidate.path_length});
                }

                if (self.move(candidate.x, candidate.y, dir)) |t| {
                    if (t.x == candidate.lastx and t.y == candidate.lasty) {
                        continue;
                    }

                    try pq.add(.{
                        .x = t.x,
                        .y = t.y,
                        .path_length = candidate.path_length + 1,
                        .depth = depth,
                        .lastx = candidate.x,
                        .lasty = candidate.y,
                    });
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
                    map.set(i - 1, y, Tile.portal(.{c, b[i]}, .Inner));
                } else {
                    map.set(i - 1, y - 1, Tile.portal(.{c, b[i]}, .Inner));
                }
            } else {
                map.set(i - 1, y, Tile.portal(.{c, b[i]}, .Outer));
            }
        }
    }
}

fn insertHorizontalPortals(map: *Map, y: usize, line: []const u8) void {
    for (line[0 .. line.len - 1]) |c, i| {
        if (alphabetic(c) and alphabetic(line[i + 1])) {
            if (i + 2 >= line.len or line[i + 2] == ' ') {
                map.set(i - 1, y, Tile.portal(.{line[i], line[i + 1]}, if (i + 2 >= line.len) .Outer else .Inner));
            } else {
                map.set(i, y, Tile.portal(.{line[i], line[i + 1]}, if(i == 0) .Outer else .Inner));
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
    std.debug.warn("{}\n", .{try map.aaToZzRecursive()});
}
