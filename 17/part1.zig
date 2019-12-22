const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Vm = struct {
    pc: usize = 0,
    rel: i64 = 0,
    in: ?i64 = null,
    memory: []i64,

    fn run(self: *Vm) !?i64 {
        while (true) {
            switch (@mod(self.memory[self.pc], 100)) {
                1 => {
                    (try self.addrOperand(2)).* = (try self.readOperand(0)) + (try self.readOperand(1));
                    self.pc += 4;
                },
                2 => {
                    (try self.addrOperand(2)).* = (try self.readOperand(0)) * (try self.readOperand(1));
                    self.pc += 4;
                },
                3 => {
                    if (self.in == null) {
                        return error.InputRequired;
                    }

                    (try self.addrOperand(0)).* = self.in.?;
                    self.in = null;

                    self.pc += 2;
                },
                4 => {
                    const out = try self.readOperand(0);
                    self.pc += 2;
                    return out;
                },
                5 => {
                    const cond = try self.readOperand(0);
                    if (cond != 0) {
                        self.pc = @intCast(usize, try self.readOperand(1));
                    } else {
                        self.pc += 3;
                    }
                },
                6 => {
                    const cond = try self.readOperand(0);
                    if (cond == 0) {
                        self.pc = @intCast(usize, try self.readOperand(1));
                    } else {
                        self.pc += 3;
                    }
                },
                7 => {
                    const a = try self.readOperand(0);
                    const b = try self.readOperand(1);
                    (try self.addrOperand(2)).* = @boolToInt(a < b);
                    self.pc += 4;
                },
                8 => {
                    const a = try self.readOperand(0);
                    const b = try self.readOperand(1);
                    (try self.addrOperand(2)).* = @boolToInt(a == b);
                    self.pc += 4;
                },
                9 => {
                    self.rel += try self.readOperand(0);
                    self.pc += 2;
                },
                99 => return null,
                else => return error.InvalidInstruction
            }
        }
    }

    fn addrOperand(self: *Vm, index: usize) !*i64 {
        const opcode = self.memory[self.pc];
        var mode = @divTrunc(opcode, 100);

        var i: usize = 0;
        while (i < index) : (i += 1) {
            mode = @divTrunc(mode, 10);
        }

        mode = @mod(mode, 10);
        const operand = self.memory[self.pc + index + 1];

        return switch (mode) {
            0 => &self.memory[@intCast(usize, operand)],
            2 => &self.memory[@intCast(usize, operand + self.rel)],
            else => return error.InvalidParameterMode
        };
    }

    fn readOperand(self: *Vm, index: usize) !i64 {
        const opcode = self.memory[self.pc];
        var mode = @divTrunc(opcode, 100);

        var i: usize = 0;
        while (i < index) : (i += 1) {
            mode = @divTrunc(mode, 10);
        }

        mode = @mod(mode, 10);
        const operand = self.memory[self.pc + index + 1];

        return switch (mode) {
            0 => self.memory[@intCast(usize, operand)],
            1 => operand,
            2 => self.memory[@intCast(usize, operand + self.rel)],
            else => error.InvalidParameterMode
        };
    }
};


const Map = struct {
    const width = 51;
    const height = 51;
    data: [Map.width * Map.height]u8 = [_]u8{' '} ** (Map.width * Map.height),

    fn draw(self: *Map) void {
        std.debug.warn("\x1b[?25l\x1b[2J\x1b[H", .{});
        var y: usize = 0;
        while (y < Map.height) : (y += 1) {
            for (self.data[y * Map.width .. (y + 1) * Map.width]) |v, x| {
                std.debug.warn("{c}", .{v});
            }

            std.debug.warn("\n", .{});
        }
    }

    fn get(self: *Map, x: usize, y: usize) u8 {
        return self.data[y * Map.width + x];
    }

    fn set(self: *Map, x: usize, y: usize, value: u8) void {
        self.data[y * Map.width + x] = value;
    }

    fn index(self: *Map, x: usize, y: usize) usize {
        return y * Map.width + x;
    }

    fn alignment(self: *Map) usize {
        var al: usize = 0;

        var y: usize = 1;
        while (y < Map.height - 1) : (y += 1) {
            var x: usize = 1;
            while (x < Map.width - 1) : (x += 1) {
                if (self.get(x, y) == '#' and self.get(x - 1, y) == '#' and self.get(x + 1, y) == '#' and self.get(x, y - 1) == '#' and self.get(x, y + 1) == '#') {
                    std.debug.warn("{} {} {}\n", .{x, y, x * y});
                    al += x * y;
                }
            }
        }

        return al;
    }
};

pub fn main() !void {
    var memory = [_]i64{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var vm = Vm {
        .memory = &memory
    };

    var map = Map {};

    i = 0;
    while (try vm.run()) |out| {
        const c = @intCast(u8, out);
        if (c == 10) {
            continue;
        }
        // std.debug.warn("{c}", .{c});
        map.data[i] = c;
        i += 1;
    }

    map.draw();
    std.debug.warn("{}\n", .{map.alignment()});
}
