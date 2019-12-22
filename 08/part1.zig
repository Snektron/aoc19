const std = @import("std");

const input = @embedFile("input.txt");
const width = 25;
const height = 6;

pub fn main() void {
    var i: usize = 0;

    var fewest: usize = 999;
    var fewest_i: usize = 0;

    while (i < input.len) : (i += width * height) {
        const chunk = input[i .. i + width * height];

        var zeros: usize = 0;
        for (chunk) |v| {
            if (v == '0') {
                zeros += 1;
            }
        }

        if (zeros < fewest) {
            fewest = zeros;
            fewest_i = i;
        }
    }

    var ones: usize = 0;
    var twos: usize = 0;

    for (input[fewest_i .. fewest_i + width * height]) |v| {
        if (v == '1') {
            ones += 1;
        } else if (v == '2') {
            twos += 1;
        }
    }

    std.debug.warn("{}\n", ones * twos);
}
