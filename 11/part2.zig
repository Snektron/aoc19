const std = @import("std");

const input = @embedFile("input.txt");

const Hull = struct {
    panels: []bool,
    painted: []bool,
    width: usize,
    height: usize,
    total_unique_painted: usize = 0,

    fn index(self: *Hull, x: i64, y: i64) usize {
        return self.width * @intCast(usize, y) + @intCast(usize, x);
    }

    fn paint(self: *Hull, x: i64, y: i64, color: bool) void {
        self.panels[self.index(x, y)] = color;
        if (!self.painted[self.index(x, y)]) {
            self.painted[self.index(x, y)] = true;
            self.total_unique_painted += 1;
        }
    }

    fn get(self: *Hull, x: i64, y: i64) bool {
        return self.panels[self.index(x, y)];
    }
};

const Vm = struct {
    pc: usize = 0,
    rel: i64 = 0,
    in: usize = 0,
    out: usize = 0,
    memory: []i64,

    hull: Hull,
    x: i64,
    y: i64,
    dx: i64,
    dy: i64,

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
                    (try self.addrOperand(0)).* = @boolToInt(self.hull.get(self.x, self.y));
                    self.in += 1;
                    self.pc += 2;
                },
                4 => {
                    const value = try self.readOperand(0);
                    if (@mod(self.out, 2) == 0) {
                        // painting the panel
                        self.hull.paint(self.x, self.y, value != 0);
                        std.debug.warn("{} {}\n", .{self.x, self.y});
                    } else {
                        // moving around
                        if (value == 0) {
                            const tmp = self.dy;
                            self.dy = self.dx;
                            self.dx = -tmp;
                        } else {
                            const tmp = self.dy;
                            self.dy = -self.dx;
                            self.dx = tmp;
                        }

                        self.y += self.dy;
                        self.x += self.dx;
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
    var memory = [_]i64{0} ** 2048;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var panels = [_]bool{false} ** (80 * 80);
    var painted = [_]bool{false} ** (80 * 80);
    var hull = Hull {
        .panels = &panels,
        .painted = &painted,
        .width = 80,
        .height = 80
    };

    hull.paint(16, 32, true);

    var vm = Vm {
        .memory = &memory,
        .hull = hull,
        .x = 16,
        .y = 32,
        .dx = 0,
        .dy = 1
    };

    try vm.run();
    std.debug.warn("{}\n", .{ vm.hull.total_unique_painted });

    var j: usize = 0;
    while (j <= 80 * 32) : (j += 80) {
        for (panels[j .. j + 80]) |x| {
            const col = if (x) "#" else ".";
            std.debug.warn("{}", .{ col });
        }
        std.debug.warn("\n", .{});
    }
}
