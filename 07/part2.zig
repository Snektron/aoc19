const std = @import("std");
const builtin = @import("builtin");

const input = @embedFile("input.txt");

const Vm = struct {
    pc: usize = 0,
    in: usize = 0,
    out: usize = 0,
    memory: []i64,
    input: []i64,
    output: []i64,

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
                    if (self.in == self.input.len) {
                        return error.InputTooSmall;
                    }

                    self.addrOperand(0).* = self.input[self.in];
                    self.in += 1;
                    self.pc += 2;
                },
                4 => {
                    if (self.out == self.output.len) {
                        return error.OutputTooSmall;
                    }

                    self.output[self.out] = try self.readOperand(0);
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

fn trySequence(seq: *[5]i64, mem: *[1024]i64) !i64 {
    var amp: i64 = 0;
    var work_mem: [5][1024]i64 = undefined;
    var inputs: [5][1024]i64 = undefined;
    var outputs: [5][1024]i64 = undefined;
    var vms: [5]Vm = undefined;

    for (seq) |phase, i| {
        std.mem.copy(i64, &work_mem[i], mem);

        for (inputs[i]) |*in| in.* = 0;
        for (outputs[i]) |*out| out.* = 0;

        inputs[i][0] = phase;

        vms[i] = Vm {
            .memory = &work_mem[i],
            .input = inputs[i][0 .. 1],
            .output = &outputs[i],
        };
    }

    var i: usize = 0;
    while (true) {
        const input_len = vms[i].input.len;
        inputs[i][input_len] = amp;
        vms[i].input = inputs[i][0 .. input_len + 1];

        var needs_input = false;
        vms[i].run() catch |err| switch (err) {
            error.InputTooSmall => {
                needs_input = true;
            },
            else => return err
        };

        amp = vms[i].output[vms[i].out - 1];

        if (i == seq.len - 1 and !needs_input) {
            break;
        }

        i = @mod(i + 1, seq.len);
    }

    return amp;
}

fn nextPermutation(seq: []i64) bool {
    var i: usize = seq.len - 1;

    while (true) {
        const a = i;
        i -= 1;

        if (seq[i] < seq[a]) {
            var b = seq.len - 1;

            while (!(seq[i] < seq[b])) {
                b -= 1;
            }

            const x = seq[i];
            seq[i] = seq[b];
            seq[b] = x;

            std.mem.reverse(i64, seq[a .. seq.len]);
            return true;
        }

        if (i == 0) {
            std.mem.reverse(i64, seq[0 .. seq.len]);
            return false;
        }
    }
}

pub fn main() !void {
    var memory = [_]i64{0} ** 1024;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var seq = [_]i64{ 5, 6, 7, 8, 9 };
    var maxamp: i64 = 0;

    while (true) {
        const amp = try trySequence(&seq, &memory);

        if (amp > maxamp) {
            maxamp = amp;
        }

        if (!nextPermutation(&seq)) {
            break;
        }
    }

    std.debug.warn("{}\n", maxamp);
}
