const std = @import("std");

const Disassembler = struct {
    pc: usize = 0,
    memory: []i64,

    const OperandType = enum {
        Absolute,
        Immediate,
        Relative,
        Invalid
    };

    const Instruction = struct {
        offset: usize,
        data: []i64,

        fn dump(self: Instruction) void {
            const args = Disassembler.instructionSize(self.data[0]);
            var i: usize = 1;
            std.debug.warn("0x{X:0>4}     {}", .{self.offset, self.mnemoric()});
            while (i < args) : (i += 1) {
                if (i != 1) {
                    std.debug.warn(",", .{});
                }
                std.debug.warn(" ", .{});

                switch (self.operandType(i)) {
                    .Absolute => std.debug.warn("[{}]", .{self.data[i]}),
                    .Immediate => std.debug.warn("{}", .{self.data[i]}),
                    .Relative => std.debug.warn("[rel + {}]", .{self.data[i]}),
                    .Invalid => std.debug.warn("(invalid: {})", .{self.data[i]})
                }
            }

            std.debug.warn("\n", .{});
        }

        fn mnemoric(self: Instruction) []const u8 {
            return switch (@mod(self.data[0], 100)) {
                1 => "add",
                2 => "mul",
                3 => "in",
                4 => "out",
                5 => "jnz",
                6 => "jz",
                7 => "lt",
                8 => "eq",
                9 => "rel",
                99 => "exit",
                else => "(invalid)"
            };
        }

        fn operandType(self: Instruction, offset: usize) OperandType {
            const opcode = self.data[0];
            var mode = @divTrunc(opcode, 100);

            var i: usize = 0;
            while (i < offset) : (i += 1) {
                mode = @divTrunc(mode, 10);
            }

            mode = @mod(mode, 10);

            return switch (mode) {
                0 => .Absolute,
                1 => .Immediate,
                2 => .Relative,
                else => .Invalid
            };
        }
    };

    fn instructionSize(opcode: i64) usize {
        return switch (@mod(opcode, 100)) {
            1 => 4,
            2 => 4,
            3 => 2,
            4 => 2,
            5 => 3,
            6 => 3,
            7 => 4,
            8 => 4,
            9 => 2,
            99 => 1,
            else => 1
        };
    }

    fn nextInstruction(self: *Disassembler) ?Instruction {
        if (self.pc < self.memory.len) {
            const size = Disassembler.instructionSize(self.memory[self.pc]);

            defer self.pc += size;
            return Instruction {
                .offset = self.pc,
                .data = self.memory[self.pc .. self.pc + size]
            };
        } else {
            return null;
        }
    }
};

pub fn main() !void {
    const args = std.os.argv;
    if (args.len <= 1) {
        std.debug.warn("usage: intcode-dump <intcode file>\n", .{});
    }

    var file = try std.fs.cwd().openFileC(args[1], .{});
    defer file.close();

    const input = try file.inStream().stream.readAllAlloc(std.heap.page_allocator, std.math.maxInt(usize));

    var intcode = std.ArrayList(i64).init(std.heap.page_allocator);

    var ints = std.mem.separate(std.mem.trim(u8, input, "\n"), ",");
    while (ints.next()) |int| {
        try intcode.append(try std.fmt.parseInt(i64, int, 10));
    }

    var disas = Disassembler{
        .memory = intcode.toSlice()
    };

    while (disas.nextInstruction()) |instr| {
        instr.dump();
    }
}
