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
                    self.addrOperand(0).* = self.input[self.in];
                    self.in += 1;
                    self.pc += 2;
                },
                4 => {
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

fn trySequence(seq: []i64, mem: var) !i64 {
    var amp: i64 = 0;
    var work_mem: [@typeInfo(@typeOf(mem)).Pointer.child.len]i64 = undefined;

    for (seq) |i| {
        std.mem.copy(i64, &work_mem, mem);

        var output: [1]i64 = undefined;

        var vm = Vm {
            .memory = &work_mem,
            .input = &[_]i64{ i, amp },
            .output = &output
        };

        try vm.run();

        amp = output[0];
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

fn oef() void {
    var seq = [_]i64{ 0, 1, 2, 3, 4 };

    var fact: usize = 1;
    var j = seq.len;
    while (j > 1) : (j -= 1) {
        fact *= j;
    }

    var i: usize = 0;
    while (i < fact) {
        i += 1;
        // for (seq) |x| std.debug.warn("{}", x);
        // std.debug.warn("\n");

        const k = @mod(i, seq.len * 2);
        const swap = if (k >= seq.len) seq.len * 2 - k else k;
        // std.debug.warn("{} {} {} | ", i, k, swap);

        if (swap == 0) {
            const tmp = seq[seq.len - 1];
            std.debug.warn("End: {} <=> {}\n", seq.len - 2, seq.len - 1);
            seq[seq.len - 1] = seq[seq.len - 2];
            seq[seq.len - 2] = tmp;
        } else if (swap == seq.len) {
            std.debug.warn("Begin: {} <=> {}\n", @as(i32, 0), @as(i32, 1));
            const tmp = seq[0];
            seq[0] = seq[1];
            seq[1] = tmp;
        } else {
            std.debug.warn("{} <=> {}\n", swap - 1, swap);
            const tmp = seq[swap - 1];
            seq[swap - 1] = seq[swap];
            seq[swap] = tmp;
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

    // var seq = [_]i64{ 0, 1, 2, 3, 4 };
    // var maxamp: i64 = 0;

    // while (true) {
    //     const amp = try trySequence(&seq, &memory);

    //     if (amp > maxamp) {
    //         maxamp = amp;
    //     }

    //     if (!nextPermutation(&seq)) {
    //         break;
    //     }
    // }

    // std.debug.warn("{}\n", maxamp);

    oef();
}
