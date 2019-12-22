const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");
const deck_size: usize = 119315717514047;
const iterations: usize = 101741582076661;

const LinearMap = struct {
    a: i128,
    b: i128,

    fn identity() LinearMap {
        return .{.a = 1, .b = 0};
    }

    fn combine(self: *LinearMap, a: i128, b: i128, m: i128) void {
        self.a = @mod(self.a * a, m);
        self.b = @mod(a * self.b + b, m);
    }

    fn square(self: *LinearMap, m: i128) void {
        self.combine(self.a, self.b, m);
    }

    fn repeatSquare(self: *LinearMap, n: usize, m: i128) void {
        var i: usize = 1;
        while (i < n) : (i += 1) {
            self.square(m);
        }
    }

    fn pow(self: *LinearMap, n: i128, m: i128) void {
        var i: usize = 1;
        var map = self.*;
        while (i < n) : (i += 1) {
            self.combine(map.a, map.b, m);
        }
    }

    fn y(self: LinearMap, x: i128, m: i128) i128 {
        return @mod(self.a * x + self.b, m);
    }

    fn dump(self: LinearMap) void {
        std.debug.warn("{}x + {}\n", .{self.a, self.b});
    }
};

fn shuffleToMap(n: i128) !LinearMap {
    var map = LinearMap.identity();

    var it = std.mem.separate(input, "\n");
    while (it.next()) |line| {
        var a: i128 = 1;
        var b: i128 = 0;

        if (std.mem.startsWith(u8, line, "cut")) {
            b = -(try std.fmt.parseInt(i128, line["cut ".len ..], 10));
        } else if (std.mem.startsWith(u8, line, "deal with increment")) {
            a = try std.fmt.parseInt(i128, line["deal with increment ".len ..], 10);
        } else if (std.mem.eql(u8, "deal into new stack", line)) {
            a = -1;
            b = -1;
        } else {
            return error.InvalidOperation;
        }

        map.combine(a, b, n);
    }

    return map;
}

fn solveCongruence(map: LinearMap, m: i128) i128 {
    const a = @mod(map.a, m);
    const b = @mod(map.b, m);

    if (b == 0) {
        return 0;
    }

    const y = solveCongruence(.{.a = m, .b = -b}, a);
    return @divExact(m * y + b, a);
}

pub fn main() !void {
    const n = deck_size;
    const it = iterations;
    const map = try shuffleToMap(n);
    map.dump();

    var powmap = LinearMap.identity();

    var i: usize = 0;
    while (i < 64) : (i += 1) {
        if (it & (@as(usize, 1) << @intCast(u6, i)) != 0) {
            var m = map;
            m.repeatSquare(i + 1, n);
            powmap.combine(m.a, m.b, n);
        }
    }

    powmap.dump();

    const target = 2020;
    const cmb = @mod(target - powmap.b, @intCast(i128, n));
    std.debug.warn("{} = {}x (mod {})\n", .{cmb, powmap.a, n});
    const x = solveCongruence(.{.a = powmap.a, .b = cmb}, n);
    std.debug.warn("{}\n", .{x});
    std.debug.warn("{}\n", .{powmap.y(x, n)});
}
