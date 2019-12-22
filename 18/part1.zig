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

const KeySet = struct {
    keys: u64,

    fn init() KeySet {
        return .{.keys = 0};
    }

    fn hasKey(self: KeySet, key: u8) bool {
        return (self.keys >> @intCast(u6, key - 'a')) & 1 == 1;
    }

    fn setKey(self: *KeySet, key: u8) void {
        self.keys |= @as(u64, 1) << @intCast(u6, (key - 'a'));
    }

    fn isComplete(self: KeySet, total_keys: usize) bool {
       return @popCount(u64, self.keys) == total_keys;
    }
};

const Map = struct {
    width: usize,
    height: usize,
    data: std.ArrayList(u8),

    fn init(width: usize, height: usize) !Map {
        var data = std.ArrayList(u8).init(std.heap.page_allocator);
        try data.resize(width * height);

        for (data.toSlice()) |*i| i.* = ' ';

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
                std.debug.warn("{c}", .{self.get(x, y)});
            }

            std.debug.warn("\n", .{});
        }
    }

    fn index(self: *Map, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    fn get(self: *Map, x: usize, y: usize) u8 {
        return self.data.toSlice()[self.index(x, y)];
    }

    fn set(self: *Map, x: usize, y: usize, value: u8) void {
        self.data.toSlice()[self.index(x, y)] = value;
    }

    fn search(self: *Map, startx: usize, starty: usize, total_keys: usize) anyerror!usize {
        const Candidate = struct {
            const Self = @This();
            x: usize,
            y: usize,
            keys: KeySet,
            path_length: usize,

            fn compare(a: Self, b: Self) bool {
                return a.path_length < b.path_length;
            }
        };

        const SeenCandidate = struct {
            x: usize,
            y: usize,
            keys: KeySet
        };

        var seen = std.AutoHashMap(SeenCandidate, void).init(std.heap.page_allocator);
        var pq = std.PriorityQueue(Candidate).init(std.heap.page_allocator, Candidate.compare);
        defer pq.deinit();

        try pq.add(.{
            .x = startx,
            .y = starty,
            .keys = KeySet.init(),
            .path_length = 0
        });

        while (pq.count() > 0) {
            const candidate = pq.remove();
            const current = self.get(candidate.x, candidate.y);

            const on_key = std.ascii.isLower(current);
            var keys = candidate.keys;

            if (on_key) {
                keys.setKey(current);
                if (keys.isComplete(total_keys)) {
                    return candidate.path_length;
                }
            }

            for ([_]Direction{.North, .West, .South, .East}) |dir| {
                const offs = dir.offset();
                const newx = @intCast(usize, @intCast(i64, candidate.x) + offs.x);
                const newy = @intCast(usize, @intCast(i64, candidate.y) + offs.y);
                const target = self.get(newx, newy);

                if (target == '#') {
                    continue;
                } else if (std.ascii.isUpper(target) and !keys.hasKey(target - 'A' + 'a')) {
                    // We don't have the key for this gate
                    continue;
                }

                const seen_can = SeenCandidate{.x = newx, .y = newy, .keys = keys};

                if ((try seen.put(seen_can, .{})) == null) {
                    try pq.add(.{
                        .x = newx,
                        .y = newy,
                        .keys = keys,
                        .path_length = candidate.path_length + 1
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
                if (self.get(x, y) != '.' and !std.ascii.isUpper(self.get(x, y))) {
                    continue;
                }

                var n: usize = 0;
                if (self.get(x + 1, y) == '#') {
                    n += 1;
                }

                if (self.get(x - 1, y) == '#') {
                    n += 1;
                }

                if (self.get(x, y + 1) == '#') {
                    n += 1;
                }

                if (self.get(x, y - 1) == '#') {
                    n += 1;
                }

                if (n >= 3) {
                    self.set(x, y, '#');
                    anychanged = true;
                }
            }
        }

        return anychanged;
    }
};

pub fn main() !void {
    var height: usize = 0;
    var width: usize = 0;
    var keys: usize = 0;

    {
        var lines = std.mem.separate(input, "\n");
        while (lines.next()) |line| {
            height += 1;
            width = std.math.max(line.len, width);

            for (line) |c| {
                if (std.ascii.isLower(c)) {
                    keys += 1;
                }
            }
        }
    }

    var map = try Map.init(width, height);
    defer map.deinit();

    var startx: usize = 0;
    var starty: usize = 0;

    {
        var it = std.mem.separate(input, "\n");
        var j: usize = 0;
        while (it.next()) |line| {
            for (line) |c, i| {
                if (c == '@') {
                    startx = i;
                    starty = j;
                }

                map.set(i, j, c);
            }

            j += 1;
        }
    }

    while (map.simplify()) continue;
    map.set(startx, starty, '.');
    map.draw();

    std.debug.warn("{}\n", .{try map.search(startx, starty, keys)});
}
