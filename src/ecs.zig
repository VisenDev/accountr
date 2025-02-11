const std = @import("std");
const SparseSet = @import("sparse_set.zig").SparseSet;
const Allocator = std.mem.Allocator;

const Id = enum(usize) {
    _,
};

pub fn StructOfSparseSet(comptime T: type) type {
    if (@typeInfo(T) != .@"struct") @compileError("Invalid type");
    const info = @typeInfo(T).@"struct";
    var fields: [info.fields.len]std.builtin.Type.StructField = undefined;
    for (info.fields, 0..) |field, i| {
        const SSet = SparseSet(field.type, usize);
        const default: SSet = .{};
        fields[i] = .{
            .type = SSet,
            .name = field.name,
            .default_value_ptr = &default,
            .is_comptime = false,
            .alignment = @alignOf(SSet),
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
        const component_info = @typeInfo(StructOfSparseSet(T)).@"struct".fields;

        max_id: usize,
        ids: std.ArrayListUnmanaged(Id),
        components: StructOfSparseSet(T),

        pub fn init(a: Allocator) !@This() {
            const initial_cap = 128;
            var result: @This() = .{
                .max_id = initi
                .ids = try .init(a),
                .components = .{},
            };
            inline for (component_info) |field| {
                @field(result.components, field.name) = .init();
            }
            return result;
        }

        pub fn deinit(self: *@This(), a: Allocator) void {
            inline for (component_info) |field| {
                @field(self.components, field.name).deinit(a);
            }
            self.ids.deinit();
        }

        pub fn newEntity(self: *@This(), a: Allocator) !Id {
            _ = self;
            _ = a;
        }
    };
}

const TestType = struct {
    name: []const u8,
    phone: []const u8,
    age: i32,
};

test "ecs" {
    var e = try Ecs(TestType).init(std.testing.allocator);
    _ = &e;
    defer e.deinit(std.testing.allocator);
}
