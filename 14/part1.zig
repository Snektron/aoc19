const std = @import("std");

const input = std.mem.trim(u8, @embedFile("input.txt"), "\n");

const Chemical = struct {
    name: []const u8,
    weight: u64
};

const Reaction = struct {
    reactants: []Chemical,
    product: Chemical,
    required: u64 = 0
};

fn parseChemical(in: []const u8) !Chemical {
    var it = std.mem.separate(in, " ");
    const weight = it.next().?;
    const name = it.next().?;

    return Chemical{
        .name = name,
        .weight = try std.fmt.parseInt(u64, weight, 10),
    };
}

fn findReaction(reactions: []Reaction, product: []const u8) ?usize {
    for (reactions) |reaction, i| {
        if (std.mem.eql(u8, reaction.product.name, product)) {
            return i;
        }
    }

    return null;
}

const TopologicalOrderer = struct {
    reactions: []Reaction,
    temporary_mark: []bool,
    permanent_mark: []bool,
    ordered_nodes: []usize,
    i: usize = 0,

    fn order(self: *TopologicalOrderer) !void {
        for (self.permanent_mark) |*mark| mark.* = false;
        for (self.temporary_mark) |*mark| mark.* = false;

        for (self.reactions) |*reaction, i| {
            if (self.permanent_mark[i]) {
                continue;
            }

            try self.visit(i);
        }
    }

    fn visit(self: *TopologicalOrderer, node: usize) error{NotADag}!void {
        if (self.permanent_mark[node]) {
            return;
        } else if (self.temporary_mark[node]) {
            return error.NotADag;
        }

        self.temporary_mark[node] = true;

        for (self.reactions[node].reactants) |*reactant| {
            try self.visit(findReaction(self.reactions, reactant.name).?);
        }

        self.temporary_mark[node] = false;
        self.permanent_mark[node] = true;
        self.ordered_nodes[self.i] = node;
        self.i += 1;
    }
};

fn topolocialOrder(allocator: *std.mem.Allocator, reactions: []Reaction) ![]usize {
    var orderer = TopologicalOrderer{
        .reactions = reactions,
        .temporary_mark = try allocator.alloc(bool, reactions.len),
        .permanent_mark = try allocator.alloc(bool, reactions.len),
        .ordered_nodes = try allocator.alloc(usize, reactions.len)
    };

    try orderer.order();
    return orderer.ordered_nodes;
}

fn divCeil(a: u64, b: u64) u64 {
    return @divFloor(a + b - 1, b);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var num_reactions: usize = 2;
    for (input) |c| {
        if (c == '\n') {
            num_reactions += 1;
        }
    }

    var reactions = try arena.allocator.alloc(Reaction, num_reactions);

    reactions[0] = Reaction{
        .reactants = &[0]Chemical{},
        .product = Chemical{
            .name = "ORE",
            .weight = 1
        }
    };

    var it = std.mem.separate(input, "\n");
    var j: usize = 1;
    while (it.next()) |line| {
        var num_dependents: usize = 1;
        for (line) |c| {
            if (c == ',') {
                num_dependents += 1;
            }
        }

        var dependents = try arena.allocator.alloc(Chemical, num_dependents);

        var comp_it = std.mem.separate(line, " => ");
        const dependents_str = comp_it.next().?;
        const product_str = comp_it.next().?;

        var dep_it = std.mem.separate(dependents_str, ", ");
        var i: usize = 0;
        while (dep_it.next()) |dep| {
            dependents[i] = try parseChemical(dep);
            i += 1;
        }

        const product = try parseChemical(product_str);
        reactions[j] = .{.reactants = dependents, .product = product};
        j += 1;
    }

    const order = try topolocialOrder(&arena.allocator, reactions);

    reactions[findReaction(reactions, "FUEL").?].required = 1;

    var i: usize = reactions.len;
    while (i > 0) {
        i -= 1;
        const ii = order[i];

        const required = reactions[ii].required;
        const iterations = divCeil(required, reactions[ii].product.weight);

        for (reactions[ii].reactants) |reactant| {
            const index = findReaction(reactions, reactant.name).?;
            reactions[index].required += iterations * reactant.weight;
        }
    }

    std.debug.warn("{}\n", .{ reactions[0].required });
}

const Root = struct {
    reactions: []Reaction;
};
