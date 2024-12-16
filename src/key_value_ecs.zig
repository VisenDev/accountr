const std = @import("std");
const sparse_set = @import("sparse_set.zig");
const SparseSet = sparse_set.SparseSet;

const Id = enum(u32) {
    _,
};

const json = std.json;

const HashSet = std.StringArrayHashMapUnmanaged;

const Value = union(enum) {
    string: []const u8,
    int: i64,
    float: f64,
    bool: bool,
    child: Id,
};

pub const Ecs = struct {
    components: HashSet(SparseSet(Value)),
    //components: HashSet(SparseSet([]const u8)),
    //   children: HashSet(SparseSet(Id)),
    //named_children: SparseSet(HashSet(Id)),
    pub fn addNewComponentType(self: *@This(), gpa: std.mem.Allocator, key: []const u8) !*SparseSet(Value) {
        try self.components.put(gpa, key, .{});
        return self.components.getPtr(key).?;
    }

    pub fn setComponentBasic(self: *@This(), gpa: std.mem.Allocator, entity: Id, key: []const u8, value: Value) !void {
        const maybe_set = self.components.getPtr(key);

        const set = if (maybe_set) |set| set //
        else try self.addNewComponentType(gpa, key);

        try set.set(gpa, @intFromEnum(entity), value);
    }

    fn ensureValueValid(value: anytype) void {
        if (@TypeOf(value) == Value) {
            return;
        } else { //
            const typeinfo = @typeInfo(@TypeOf(value));
            if (typeinfo == .Struct) {
                inline for (typeinfo.Struct.fields) |field| {
                    ensureValueValid(@field(value, field.name));
                }
            } else {
                @compileError("Input must be a Value or a struct containing fields of Value");
            }
        }
    }

    pub fn newEntity(self: *@This(), gpa: std.mem.Allocator) !Id {
        _ = self; // autofix
        _ = gpa; // autofix
        //TODO
        unreachable;
    }

    pub fn setComponentAdvanced(self: *@This(), gpa: std.mem.Allocator, entity: Id, key: []const u8, value: anytype) !void {
        ensureValueValid(value);
        const typeinfo = @typeInfo(@TypeOf(value));

        if (@TypeOf(value) == Value) {
            try self.setComponent(gpa, entity, key, value);
        } else {
            const child = try self.newEntity(self, gpa);
            try self.setComponent(gpa, entity, key, .{ .child = child });
            inline for (typeinfo.Struct.fields) |field| {
                self.setComponentAdvanced(gpa, child, field.name, @field(value, field.name));
            }
        }
    }
};

test "key value" {
    var ecs = Ecs{};

    const a = std.testing.allocator;
    const entity = try ecs.newEntity(a);
    try ecs.setComponentAdvanced(a, entity, "contact", .{
        .first_name = Value{ .string = "john" },
        .last_name = Value{ .string = "smith" },
    });

    const set = ecs.unionOf(&.{"contact"});
    for (set) |id| {
        const contact = ecs.getComponent(Id, id, "contact");
        const first_name = ecs.getComponent([]const u8, contact, "first_name");
        _ = first_name; // autofix
    }
}
