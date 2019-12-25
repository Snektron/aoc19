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
                    } else {
                        (try self.addrOperand(0)).* = self.input[self.in];
                    }

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
                else => |instr| {
                    std.debug.warn("{}\n", .{instr});
                    return error.InvalidInstruction;
                }
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

fn print(out: i64) void {
    if (out < 128) {
        if (out == 10) {
            std.debug.warn("\n", .{});
        } else {
            std.debug.warn("{c}", .{@intCast(u8, out)});
        }
    } else {
        std.debug.warn("{}\n", .{out});
    }
}

pub fn main() !void {
    var memory = [_]i64{0} ** 8192;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var stdin = std.io.getStdIn().inStream();

    const program =
        \\west
        \\take fixed point
        \\north
        \\take sand
        \\south
        \\east
        \\east
        \\take asterisk
        \\north
        \\north
        \\take hypercube
        \\north
        \\take coin
        \\north
        \\take easter egg
        \\south
        \\south
        \\south
        \\west
        \\north
        \\take spool of cat6
        \\north
        \\take shell
        \\west
        \\
        ;

    var in_buf: [1024]u8 = undefined;
    var in: [1024]i64 = undefined;

    for (program) |c, j| in[j] = c;

    var vm = Vm{
        .memory = &memory,
        .input = in[0 .. program.len]
    };

    while (true) {
        const out = vm.run() catch |err| switch (err) {
            error.InputRequired => {
                const in_data = (try stdin.stream.readUntilDelimiterOrEof(&in_buf, '\n')).?;
                for (in_data) |c, j| in[j] = c;
                in[in_data.len] = 10;
                vm.input = in[0 .. in_data.len + 1];
                vm.in = 0;
                continue;
            },
            else => return err
        };

        if (out) |c| {
            print(c);
        } else {
            break;
        }
    }
}
