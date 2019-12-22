const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Vm = struct {
    pc: usize = 0,
    rel: i64 = 0,
    in: ?i64 = null,
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
                    if (self.in == null) {
                        return error.InputRequired;
                    }

                    (try self.addrOperand(0)).* = self.in.?;
                    self.in = null;

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

const Map = struct {
    const width = 41;
    const height = 41;
    data: [Map.width * Map.height]u8 = [_]u8{'.'} ** (Map.width * Map.height),
    x: usize = 21,
    y: usize = 21,
    found: bool = false,

    fn draw(self: *Map) void {
        std.debug.warn("\x1b[?25l\x1b[2J\x1b[H", .{});
        var y: usize = 0;
        while (y < Map.height) : (y += 1) {
            for (self.data[y * Map.width .. (y + 1) * Map.width]) |v, x| {
                if (y == self.y and x == self.x) {
                    std.debug.warn("X", .{});
                } else {
                    std.debug.warn("{c}", .{v});
                }
            }

            std.debug.warn("\n", .{});
        }
    }

    fn get(self: *Map, x: usize, y: usize) u8 {
        return self.data[y * Map.width + x];
    }

    fn set(self: *Map, x: usize, y: usize, value: u8) void {
        self.data[y * Map.width + x] = value;
    }

    fn index(self: *Map, x: usize, y: usize) usize {
        return y * Map.width + x;
    }

    fn getDir(self: *Map, dir: usize) u8 {
        return switch (dir) {
            1 => self.get(self.x, self.y - 1),
            2 => self.get(self.x, self.y + 1),
            3 => self.get(self.x - 1, self.y),
            4 => self.get(self.x + 1, self.y),
            else => unreachable
        };
    }

    fn oxygen(self: *Map) bool {
        var back = [_]u8{' '} ** (Map.width * Map.height);

        var y: usize = 0;
        while (y < Map.height) : (y += 1) {
            var x: usize = 0;
            while (x < Map.width) : (x += 1) {
                if (self.get(x, y) == 'O') {
                    if (x > 0 and self.get(x - 1, y) == ' ') back[self.index(x - 1, y)] = 'O';
                    if (y > 0 and self.get(x, y - 1) == ' ') back[self.index(x, y - 1)] = 'O';
                    if (x < Map.width - 1 and self.get(x + 1, y) == ' ') back[self.index(x + 1, y)] = 'O';
                    if (y < Map.height - 1 and self.get(x, y + 1) == ' ') back[self.index(x, y + 1)] = 'O';
                }
            }
        }

        y = 0;
        while (y < Map.height) : (y += 1) {
            var x: usize = 0;
            while (x < Map.width) : (x += 1) {
                if (back[self.index(x, y)] == 'O') {
                    self.set(x, y, 'O');
                }
            }
        }

        var empty: usize = 0;
        y = 0;
        while (y < Map.height) : (y += 1) {
            var x: usize = 0;
            while (x < Map.width) : (x += 1) {
                if (self.get(x, y) == ' ') {
                    empty += 1;
                }
            }
        }

        return empty == 0;
    }
};

fn tryMove(vm: *Vm, map: *Map, dir: usize) !i64 {
    vm.in = @intCast(i64, dir);

    var x: usize = map.x;
    var y: usize = map.y;

    if (map.get(x, y) == '.') {
        map.set(x, y, ' ');
    }

    switch (dir) {
        1 => y -= 1,
        2 => y += 1,
        3 => x -= 1,
        4 => x += 1,
        else => unreachable
    }

    if (try vm.run()) |status| {
        switch (status) {
            0 => map.set(x, y, '#'),
            1 => {map.x = x; map.y = y;},
            2 => {map.x = x; map.y = y; map.set(x, y, 'O');},
            else => unreachable
        }

        //std.time.sleep(30000000);
        //map.draw();
        return status;
    }

    return -1;
}

fn oppositeDir(dir: usize) usize {
    return switch (dir) {
        1 => 2,
        2 => 1,
        3 => 4,
        4 => 3,
        else => unreachable
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var memory = [_]i64{0} ** 4096;
    var i: usize = 0;

    var ints = std.mem.separate(input, ",");
    while (ints.next()) |int| {
        memory[i] = try std.fmt.parseInt(i64, int, 10);
        i += 1;
    }

    var vm = Vm {
        .memory = &memory
    };

    var map = Map{};
    defer std.debug.warn("\x1b[?25h", .{});

    var stack = try arena.allocator.alloc(usize, 100000);
    var sp: usize = 0;

    i = 0;
    outer: while (i < 100000) : (i += 1) {
        var dir: usize = 1;
        while (dir <= 4) : (dir += 1) {
            if (map.getDir(dir) == '.') {
                break;
            }
        } else {
            if (sp == 0) {
                break :outer;
            }
            sp -= 1;

            _ = try tryMove(&vm, &map, oppositeDir(stack[sp]));
            continue;
        }

        switch (try tryMove(&vm, &map, dir)) {
            0 => {
                // wall
                continue;
            },
            1, 2 => {
                // moved
                stack[sp] = dir;
                sp += 1;
            },
            else => unreachable
        }
    }

    i = 0;
    while (true) {
        i += 1;
        const finished = map.oxygen();
        if (finished) {
            break;
        }
    }

    //std.debug.warn("{}\n", .{i});
}
