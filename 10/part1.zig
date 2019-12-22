const std = @import("std");

const input = @embedFile("input.txt");

const Cell = enum {
    Asteroid,
    Empty
};

const Field = struct {
    cells: []Cell,
    w: usize,
    h: usize,

    fn index(self: *const Field, x: usize, y: usize) usize {
        return y * self.w + x;
    }

    fn at(self: *const Field, x: usize, y: usize) Cell {
        return self.cells[self.index(x, y)];
    }
};

const Ray = struct {
    x: i64,
    y: i64,

    dx: i64,
    dy: i64,

    fn init(x: usize, y: usize, tx: usize, ty: usize) Ray {
        var dx = @intCast(i64, tx) - @intCast(i64, x);
        var dy = @intCast(i64, ty) - @intCast(i64, y);

        const divisor = gcd(i64, std.math.absInt(dx) catch unreachable, std.math.absInt(dy) catch unreachable);

        return .{
            .x = @intCast(i64, x),
            .y = @intCast(i64, y),

            .dx = @divExact(@intCast(i64, dx), divisor),
            .dy = @divExact(@intCast(i64, dy), divisor)
        };
    }

    fn advance(self: *Ray) void {
        self.x += self.dx;
        self.y += self.dy;
    }

    fn inBounds(self: *Ray, w: usize, h: usize) bool {
        if (self.x < 0 or self.y < 0) {
            return false;
        }

        return @intCast(usize, self.x) < w and @intCast(usize, self.y) < h;
    }
};

fn gcd(comptime T: type, a: T, b: T) T {
    var x = a;
    var y = b;

    while (y != 0) {
        const tmp = y;
        y = @mod(x, y);
        x = tmp;
    }

    return x;
}

fn cast(field: Field, visited: []bool, ray: *Ray) usize {
    ray.advance();

    const vis_ptr = &visited[field.index(@intCast(usize, ray.x), @intCast(usize, ray.y))];
    if (vis_ptr.*) {
        return 0;
    }

    vis_ptr.* = true;

    while (ray.inBounds(field.w, field.h)) : (ray.advance()) {
        if (field.at(@intCast(usize, ray.x), @intCast(usize, ray.y)) == .Asteroid) {
            return 1;
        }
    }

    return 0;
}

fn countSeen(field: Field, x: usize, y: usize) usize {
    var visited = [_]bool{false} ** input.len;
    var seen: usize = 0;

    var tx: usize = 0;
    while (tx < field.w) : (tx += 1) {
        var ty: usize = 0;
        while (ty < field.h) : (ty += 1) {
            if (x != tx or y != ty) {
                var ray = Ray.init(x, y, tx, ty);
                seen += cast(field, &visited, &ray);
            }
        }
    }

    return seen;
}

pub fn main() void {
    var cells: [input.len]Cell = undefined;
    var w: usize = undefined;
    var h: usize = 0;

    var it = std.mem.separate(input, "\n");

    var i: usize = 0;
    while (it.next()) |line| {
        for (line) |c| {
            cells[i] = if (c == '#') .Asteroid else .Empty;
            i += 1;
        }

        w = line.len;
        h += 1;
    }

    var field = Field{
        .cells = &cells,
        .w = w,
        .h = h
    };

    var max_seen: usize = 0;

    var tx: usize = 0;
    while (tx < field.w) : (tx += 1) {
        var ty: usize = 0;
        while (ty < field.h) : (ty += 1) {
            if (field.at(tx, ty) == .Asteroid) {
                const seen = countSeen(field, tx, ty);
                if (seen > max_seen) {
                    max_seen = seen;
                }
            }
        }
    }

    std.debug.warn("{}\n", .{ max_seen });
}
