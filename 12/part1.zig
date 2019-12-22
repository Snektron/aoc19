const std = @import("std");

const input = @embedFile("input.txt");

const Vec3 = struct {
    x: i64,
    y: i64,
    z: i64
};

const Planet = struct {
    pos: [3]i64,
    vel: [3]i64
};

fn dumpPlanets(planets: []Planet) void {
    for (planets) |*planet| {
        std.debug.warn("pos<x={}, y={}, z={}>, vel<x={}, y={}, z={}>\n", .{
            planet.pos[0],
            planet.pos[1],
            planet.pos[2],
            planet.vel[0],
            planet.vel[1],
            planet.vel[2],
        });
    }
}

fn simulate(planets: []Planet) void {
    for (planets) |*a| {
        for (planets) |*b| {
            if (a != b) {
                for (a.vel) |*av, i| {
                    if (a.pos[i] > b.pos[i]) {
                        av.* -= 1;
                    } else if (a.pos[i] < b.pos[i]) {
                        av.* += 1;
                    }
                }
            }
        }
    }

    for (planets) |*planet| {
        for (planet.pos) |*p, i| {
            p.* += planet.vel[i];
        }
    }
}

fn energy(planets: []Planet) i64 {
    var total: i64 = 0;

    for (planets) |*planet| {
        var kin: i64 = 0;
        var pot: i64 = 0;
        for (planet.pos) |p| {
            pot += std.math.absInt(p) catch unreachable;
        }

        for (planet.vel) |v| {
            kin += std.math.absInt(v) catch unreachable;
        }

        total += kin * pot;
    }

    return total;
}

pub fn main() !void {
    var lines = std.mem.separate(input, "\n");
    var planets: [4]Planet = undefined;

    var i: usize = 0;
    while (lines.next()) |line| {
        var coords = std.mem.separate(line, " ");
        planets[i] = .{
            .pos = .{
                try std.fmt.parseInt(i64, coords.next().?, 10),
                try std.fmt.parseInt(i64, coords.next().?, 10),
                try std.fmt.parseInt(i64, coords.next().?, 10)
            },
            .vel = .{0, 0, 0}
        };

        i += 1;
    }

    i = 0;
    while (i < 1000) : (i += 1) {
        simulate(&planets);
    }

    dumpPlanets(&planets);
    std.debug.warn("Energy: {}\n", .{ energy(&planets) });
}
