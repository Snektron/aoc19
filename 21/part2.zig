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

//  ABCDEFGHI
// @___#   #
// @___##   #
// @___###___

// jump = !(A ^ B ^ C) ^ D ^ (H v (E ^ I) v (E ^ F))
//      = !(A ^ B ^ C) ^ D ^ (H v (E ^ (I v F))

pub fn main() !void {
    var memory = [_]i64{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    const program =
        \\OR I J
        \\OR F J
        \\AND E J
        \\OR H J
        \\AND D J
        \\OR A T
        \\AND B T
        \\AND C T
        \\NOT T T
        \\AND T J
        \\RUN
        \\
        ;

    var in: [program.len]i64 = undefined;
    for (program) |c, j| in[j] = c;

    var vm = Vm{
        .memory = &memory,
        .input = &in
    };

    while (try vm.run()) |out| {
        if (out < 128) {
            std.debug.warn("{c}", .{@intCast(u8, out)});
        } else {
            std.debug.warn("{}\n", .{out});
        }
    }
}