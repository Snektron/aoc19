const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Vm = struct {
    pc: usize = 0,
    rel: i64 = 0,
    in: usize = 0,
    input: []i64,
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
                    if (self.in >= self.input.len) {
                        return error.InputRequired;
                    }

                    (try self.addrOperand(0)).* = self.input[self.in];
                    self.in += 1;

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

pub fn main() !void {
    var memory = [_]i64{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var vm_in = [_]i64{0, 0};
    var vm_mem: [4096]i64 = undefined;

    var affected: usize = 0;
    var y: i64 = 560 - 2;
    while (y < 560 + 100 - 2) : (y += 1) {
        var x: i64 = 1020 - 4;
        while (x < 1020 + 100 - 4) : (x += 1) {
            std.mem.copy(i64, &vm_mem, &memory);
            vm_in[0] = x;
            vm_in[1] = y;

            var vm = Vm {
                .memory = &vm_mem,
                .input = &vm_in
            };

            switch ((try vm.run()).?) {
                0 => std.debug.warn(".", .{}),
                1 => {
                    affected += 1;
                    std.debug.warn("#", .{});
                },
                else => unreachable
            }
        }

        std.debug.warn("\n", .{});
    }

    std.debug.warn("{}\n", .{affected});
}
