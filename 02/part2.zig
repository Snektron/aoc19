const std = @import("std");

fn run(mem: []u64) !u64 {
    var pc: usize = 0;
    while (true) {
        switch (mem[pc]) {
            1 => mem[mem[pc + 3]] = mem[mem[pc + 1]] + mem[mem[pc + 2]],
            2 => mem[mem[pc + 3]] = mem[mem[pc + 1]] * mem[mem[pc + 2]],
            99 => return mem[0],
            else => return error.InvalidInstruction
        }

        pc += 4;
    }
}

pub fn main() !void {
    var in = std.io.getStdIn().inStream();
    var buf: [10]u8 = undefined;
    var mem = [_]u64{0} ** 150;

    var i: usize = 0;
    while (try in.stream.readUntilDelimiterOrEof(&buf, ',')) |str| {
        if (str[str.len - 1] == '\n') {
            str = str[0 .. str.len - 1];
        }

        mem[i] = try std.fmt.parseInt(u64, str, 10);
        i += 1;
    }

    var work_mem: [mem.len]u64 = undefined;

    var noun: usize = 0;
    var verb: usize = 0;

    while (verb < 100) : (if (noun == 100) {noun = 0; verb += 1;} else {noun += 1;}) {
        std.mem.copy(u64, &work_mem, &mem);
        work_mem[1] = noun;
        work_mem[2] = verb;

        const result = run(&work_mem) catch continue;

        if (result == 19690720) {
            std.debug.warn("noun: {}, verb: {}, 100 * noun + verb: {}\n", noun, verb, 100 * noun + verb);
        }
    }
}
