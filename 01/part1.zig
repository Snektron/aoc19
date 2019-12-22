const std = @import("std");
const parseInt = std.fmt.parseInt;

fn fuelRequirement(mass: i64) i64 {
    return @divTrunc(mass, 3) - @as(i64, 2);
}

pub fn main() !void {
    var in = std.io.getStdIn().inStream();
    var buf: [10]u8 = undefined;

    var total: i64 = 0;

    while (try in.stream.readUntilDelimiterOrEof(&buf, '\n')) |str| {
        total += fuelRequirement(try parseInt(i64, str, 10));
    }

    std.debug.warn("{}\n", total);
}
