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

fn sim1d(pos: []i64, vel: []i64) void {
    for (pos) |a, i| {
        for (pos) |b, j| {
            if (i != j) {
                if (a > b) {
                    vel[i] -= 1;
                } else if (a < b) {
                    vel[i] += 1;
                }
            }
        }
    }

    for (pos) |*p, i| {
        p.* += vel[i];
    }
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

    var initial: [4]Planet = undefined;
    std.mem.copy(Planet, &initial, &planets);

    var axis: usize = 0;
    while (axis < 3) : (axis += 1) {
        const ipos = [_]i64{planets[0].pos[axis], planets[1].pos[axis], planets[2].pos[axis], planets[3].pos[axis]};
        const ivel = [_]i64{0, 0, 0, 0};

        var pos = [_]i64{planets[0].pos[axis], planets[1].pos[axis], planets[2].pos[axis], planets[3].pos[axis]};
        var vel = [_]i64{0, 0, 0, 0};

        i = 0;
        while (true) {
            sim1d(&pos, &vel);
            i += 1;

            if (std.mem.eql(i64, &pos, &ipos) and std.mem.eql(i64, &vel, &ivel)) {
                std.debug.warn("Axis {}: period of {}\n", .{ axis, i });
                break;
            }

            if (i % 1000000 == 0) {
                std.debug.warn("{}...\n", .{i});
            }
        }
    }
}
