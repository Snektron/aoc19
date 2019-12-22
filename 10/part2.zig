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

const Coordinate = struct {
    x: usize,
    y: usize
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

fn cast(field: Field, visited: []bool, ray: *Ray) ?Coordinate {
    ray.advance();

    const vis_ptr = &visited[field.index(@intCast(usize, ray.x), @intCast(usize, ray.y))];
    if (vis_ptr.*) {
        return null;
    }

    vis_ptr.* = true;

    while (ray.inBounds(field.w, field.h)) : (ray.advance()) {
        const rx = @intCast(usize, ray.x);
        const ry = @intCast(usize, ray.y);
        if (field.at(rx, ry) == .Asteroid) {
            return Coordinate{.x = rx, .y = ry};
        }
    }

    return null;
}

const station = Coordinate{
        .x = 31,
        .y = 20
    };

fn laserAngle(t: Coordinate) f64 {
    return std.math.atan2(
        f64,
        -(@intToFloat(f64, t.x) - @intToFloat(f64, station.x)),
        @intToFloat(f64, t.y) - @intToFloat(f64, station.y)
    ) + std.math.pi;
}

fn laser(field: Field) void {
    var visited = [_]bool{false} ** input.len;
    var lasered: [1024]Coordinate = undefined;
    var num_lasered: usize = 0;

    var tx: usize = 0;
    while (tx < field.w) : (tx += 1) {
        var ty: usize = 0;
        while (ty < field.h) : (ty += 1) {
            if (station.x != tx or station.y != ty) {
                var ray = Ray.init(station.x, station.y, tx, ty);
                if (cast(field, &visited, &ray)) |hit| {
                    lasered[num_lasered] = hit;
                    num_lasered += 1;
                }
            }
        }
    }

    std.debug.warn("Lasered {} asteroids\n", .{num_lasered});
    std.sort.insertionSort(Coordinate, lasered[0 .. num_lasered], struct {
        fn lt(lhs: Coordinate, rhs: Coordinate) bool {
            return laserAngle(lhs) < laserAngle(rhs);
        }
    }.lt);

    const twohundredth = lasered[199];
    std.debug.warn("200th: {} {} {}\n", .{ twohundredth.x, twohundredth.y, twohundredth.x * 100 + twohundredth.y });
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

    laser(field);
}
