const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");
const deck_size = 119315717514047;
const iterations = 101741582076661;

const LinearMap = struct {
    a: i64,
    b: i64,

    fn combine(self: *LinearMap, other: LinearMap) void {
        self.a *= other.a;
        self.b = other.a * self.b + other.b;
    }

    fn y(self: LinearMap, x: i64, m: i64) i64 {
        return @mod(self.a * x + self.b, m);
    }
};

fn stepOnTheBeach(start_index: usize, n: usize) !usize {
    var index = start_index;

    var it = std.mem.separate(input, "\n");
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, "cut")) {
            const amount = try std.fmt.parseInt(i64, line["cut ".len ..], 10);
            const m = if (amount < 0) n - @intCast(usize, -amount) else @intCast(usize, amount);

            if (index < m) {
                index += n - m;
            } else {
                index -= m;
            }

            // index = @mod(index + amount, n);
        } else if (std.mem.startsWith(u8, line, "deal with increment")) {
            const increment = try std.fmt.parseInt(usize, line["deal with increment ".len ..], 10);
            // std.debug.warn("oef {}\n", .{increment});
            const old = index;
            index = @mod(index * increment, n);

            // const a = @mod(@intCast(i64, index) * -@intCast(i64, increment), @intCast(i64, n));
            std.debug.warn("{} {} | {} {}\n", .{increment, index, old, j});

        } else if (std.mem.eql(u8, "deal into new stack", line)) {
            index = n - index - 1;
            //index = @mod(-index - 1, n);
        } else {
            return error.InvalidOperation;
        }
    }

    return index;
}

pub fn main() !void {
    const n = 10007;
    var index: usize = 2019;
    std.debug.warn("Final index of {}: {}\n", .{index, try stepOnTheBeach(index, n)});
}
