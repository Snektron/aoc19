const std = @import("std");

const input = @embedFile("input.txt");

const Vm = struct {
    pc: usize = 0,
    rel: i64 = 0,
    in: usize = 0,
    out: usize = 0,
    memory: []i64,
    screen: [40 * 20]u8 = [_]u8{' '} ** (40 * 20),
    score: i64 = 0,

    x: i64 = 0,
    y: i64 = 0,

    bx: i64 = 0,
    px: i64 = 0,

    fn run(self: *Vm) !void {
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
                    (try self.addrOperand(0)).* = if (self.px < self.bx) @as(i64, 1) else if (self.px > self.bx) @as(i64, -1) else @as(i64, 0);
                    self.in += 1;
                    self.pc += 2;
                },
                4 => {
                    const value = try self.readOperand(0);
                    if (@mod(self.out, 3) == 0) {
                        self.x = value;
                    } else if (@mod(self.out, 3) == 1) {
                        self.y =  value;
                    } else {
                        if (self.x == -1 and self.y == 0) {
                            self.score = value;
                        } else {
                            self.screen[@intCast(usize, self.y * 40 + self.x)] = switch (value) {
                                0 => ' ',
                                1 => '#',
                                2 => 'X',
                                3 => '-',
                                4 => 'o',
                                else => unreachable
                            };

                            if (value == 3) {
                                self.px = self.x;
                            }

                            if (value == 4) {
                                self.bx = self.x;
                            }

                            self.draw();
                        }
                    }

                    self.out += 1;
                    self.pc += 2;
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
                99 => return,
                else => return error.InvalidInstruction
            }
        }
    }

    fn draw(self: *Vm) void {
        std.debug.warn("\x1b[2J\x1b[H", .{});
        var y: usize = 0;
        while (y < 20 * 40) : (y += 40) {
            for (self.screen[y .. y + 40]) |v| {
                std.debug.warn("{c}", .{v});
            }

            std.debug.warn("\n", .{});
        }

        std.debug.warn("score: {}\n", .{self.score});
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

pub fn main() !void {
    var timer = try std.time.Timer.start();
    var memory = [_]i64{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    memory[0] = 2;

    var vm = Vm {
        .memory = &memory
    };

    try vm.run();
    vm.draw();
    std.debug.warn("time: {} us\n", .{timer.read() / 1000});
}
