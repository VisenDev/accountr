const std = @import("std");
const SparseSet = @import("sparse_set.zig").SparseSet;

const Id = enum(usize) {
    _,
};

pub fn StructOfSparseSet(comptime T: type) type {
    if (@typeInfo(T) != .@"struct") @compileError("Invalid type");
    const info = @typeInfo(T).@"struct";
    var fields: [info.fields.len]std.builtin.Type.StructField = undefined;
    for (info.fields, 0..) |field, i| {
        fields[i] = .{
            .type = SparseSet(field.type, usize),
            .name = field.name,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(SparseSet(field.type, usize)),
        };
    }
    return @Type(
        .{
            .@"struct" = .{
                .fields = &fields,
                .layout = .auto,
                .decls = &.{},
                .is_tuple = false,
            },
        },
    );
}

pub fn Ecs(comptime T: type) type {
    return struct {
        id_cap: usize,
        ids: std.ArrayListUnmanaged(Id) = .{},
        components: StructOfSparseSet(T),

        pub fn init(a: std.mem.Allocator) !@This() {
            const id_cap = 128;
            var ids: std.ArrayListUnmanaged(Id) = try .initCapacity(a, id_cap);
            for (0..id_cap) |i| {
                try ids.append(a, i);
            }
            return .{
                .ids = ids,
                .id_cap = id_cap,
                .components = .{},
            };
        }
    };
}

const TestType = struct {
    name: []const u8,
    phone: []const u8,
    age: i32,
};

test "ecs" {
    _ = &Ecs(TestType).init(std.testing.allocator);
}
