const std = @import("std");

const input = @embedFile("input.txt");
const width = 25;
const height = 6;

pub fn main() void {
    var image: [width * height]u8 = undefined;

    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            var i: usize = 0;
            while (true) : (i += 1) {
                const color = input[(y * width + x) + i * width * height];
                if (color != '2') {
                    image[y * width + x] = color;
                    break;
                }
            }
        }
    }

    y = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            if (image[y * width + x] == '1') {
                std.debug.warn("#");
            } else {
                std.debug.warn(".");
            }
        }
        std.debug.warn("\n");
    }
}
