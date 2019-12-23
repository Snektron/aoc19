const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Vm = struct {
    pc: usize = 0,
    rel: i128 = 0,
    in: usize = 0,
    in_len: usize = 0,
    input: []i128,
    memory: []i128,

    fn run(self: *Vm) !?i128 {
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
                    if (self.in >= self.in_len) {
                        return error.InputRequired;
                        // (try self.addrOperand(0)).* = -1;
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

    fn addrOperand(self: *Vm, index: usize) !*i128 {
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

    fn readOperand(self: *Vm, index: usize) !i128 {
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

const Packet = struct {
    dst: i128,
    data: [2]i128
};

const NetworkComputer = struct {
    vm: Vm,

    fn init(addr: i128, program: []const i128) !NetworkComputer {
        const memory = try std.heap.page_allocator.alloc(i128, 4096);
        const input_memory = try std.heap.page_allocator.alloc(i128, 4096);

        var vm = Vm{
            .input = input_memory,
            .memory = memory
        };

        input_memory[0] = addr;
        vm.in_len += 1;

        std.mem.copy(i128, memory, program);
        return NetworkComputer{.vm = vm};
    }

    fn deinit(self: NetworkComputer) void {
        std.heap.page_allocator.free(self.vm.memory);
        std.heap.page_allocator.free(self.vm.input);
    }

    fn run(self: *NetworkComputer) !?Packet {
        const x = (try self.vm.run()) orelse return null;
        const y = (try self.vm.run()).?;
        const z = (try self.vm.run()).?;

        return Packet{.dst = x, .data = .{y, z}};
    }

    fn addPacket(self: *NetworkComputer, data: [2]i128) void {
        self.vm.input[self.vm.in_len] = data[0];
        self.vm.input[self.vm.in_len + 1] = data[1];
        self.vm.in_len += 2;
    }

    fn addEmptyInput(self: *NetworkComputer) void {
        self.vm.input[self.vm.in_len] = -1;
        self.vm.in_len += 1;
    }
};

pub fn main() !void {
    var memory = [_]i128{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i128, int, 10);
        i += 1;
    }

    var network: [50]NetworkComputer = undefined;
    for (network) |*c, j| {
         c.* = try NetworkComputer.init(@intCast(i128, j), &memory);
         c.addEmptyInput();
    }

    var current: usize = 0;
    var idle: usize = 0;
    var nat_packet = Packet{.dst = 255, .data = .{-1, -1}};
    while (true) {
        if (idle == 50) {
            // std.debug.warn("Idle\n", .{});
            current = 0;
            network[current].addPacket(nat_packet.data);
            std.debug.warn("{}\n", .{nat_packet.data[1]});
            // break;
        }

        const optpkt = network[current].run() catch |err| switch (err) {
            error.InputRequired => null,
            else => return err
        };

        if (optpkt) |pkt| {
            if (pkt.dst == 255) {
                nat_packet = pkt;
                // std.debug.warn("DST = NAT, X = {}, Y = {}\n", .{pkt.data[0], pkt.data[1]});
            } else {
                // std.debug.warn("DST = {}, X = {}, Y = {}\n", .{pkt.dst, pkt.data[0], pkt.data[1]});

                network[@intCast(usize, pkt.dst)].addPacket(pkt.data);
                current = @intCast(usize, pkt.dst);
                idle = 0;
            }
        } else {
            current = @mod(current + 1, 50);
            idle += 1;
        }
    }
}