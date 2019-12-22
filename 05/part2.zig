const std = @import("std");
const builtin = @import("builtin");

const input = @embedFile("input.txt");

const Vm = struct {
    pc: usize = 0,
    in: usize = 0,
    memory: []i64,
    input: []i64,

    fn run(self: *Vm) !void {
        while (true) {
            switch (@mod(self.memory[self.pc], 100)) {
                1 => {
                    self.addrOperand(2).* = (try self.readOperand(0)) + (try self.readOperand(1));
                    self.pc += 4;
                },
                2 => {
                    self.addrOperand(2).* = (try self.readOperand(0)) * (try self.readOperand(1));
                    self.pc += 4;
                },
                3 => {
                    self.addrOperand(0).* = self.input[self.in];
                    self.in += 1;
                    self.pc += 2;
                },
                4 => {
                    std.debug.warn("{}\n", try self.readOperand(0));
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
                    self.addrOperand(2).* = @boolToInt(a < b);
                    self.pc += 4;
                },
                8 => {
                    const a = try self.readOperand(0);
                    const b = try self.readOperand(1);
                    self.addrOperand(2).* = @boolToInt(a == b);
                    self.pc += 4;
                },
                99 => return,
                else => return error.InvalidInstruction
            }
        }
    }

    fn addrOperand(self: *Vm, index: usize) *i64 {
        return &self.memory[@intCast(usize, self.memory[self.pc + index + 1])];
    }

    fn readOperand(self: *Vm, operand_offset: usize) !i64 {
        const opcode = self.memory[self.pc];
        var mode = @divTrunc(opcode, 100);

        var i: usize = 0;
        while (i < operand_offset) : (i += 1) {
            mode = @divTrunc(mode, 10);
        }

        mode = @mod(mode, 10);
        const operand = self.memory[self.pc + operand_offset + 1];

        return switch (mode) {
            0 => self.memory[@intCast(usize, operand)],
            1 => operand,
            else => error.InvalidParameterMode
        };
    }
};

pub fn main() !void {
    var memory = [_]i64{0} ** 1024;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var vm = Vm {
        .memory = &memory,
        .input = &[_]i64{5}
    };

    try vm.run();
}
