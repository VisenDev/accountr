const std = @import("std");
const SparseSet = @import("sparse_set.zig").SparseSet;
const Allocator = std.mem.Allocator;

/// A unique id
pub const IdBackingInt = u32;

pub const Id = enum(IdBackingInt) {
    _,

    pub fn add(self: *Id, amount: IdBackingInt) void {
        self.* = @enumFromInt(amount + self.int());
    }

    pub fn int(self: *const Id) IdBackingInt {
        return @intFromEnum(self.*);
    }
};

const HashMap = std.StringArrayHashMapUnmanaged;

pub fn ComponentStorage(comptime ComponentTypesTuple: anytype) type {
    var fields: [ComponentTypesTuple.len]std.builtin.Type.StructField = undefined;
    inline for (ComponentTypesTuple, 0..) |ComponentType, i| {
        const default = HashMap(SparseSet(ComponentType, IdBackingInt)){};
        fields[i] = .{
            .name = @typeName(ComponentType),
            .type = SparseSet(ComponentType, IdBackingInt),
            .default_value = &default, //null, //?@as(*const SparseSet(ComponentType, IdBackingInt), &default),
            .is_comptime = false,
            .alignment = 0,
        };
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .is_tuple = false,
            .fields = &fields,
            .decls = &.{},
        },
    });
}

pub fn assertTypeAccepted(comptime T: type, comptime ComponentTypesTuple: anytype) void {
    inline for (ComponentTypesTuple) |ComponentType| {
        if (ComponentType == T) {
            return;
        }
    }
    @compileError(T ++ "is not a valid type to use in this Ecs");
}

pub fn Ecs(comptime ComponentTypesTuple: anytype) type {
    return struct {
        components: ComponentStorage(ComponentTypesTuple),
        max_id: Id = @enumFromInt(0),
        free_ids: std.ArrayListUnmanaged(Id) = .{},

        const Self = @This();

        pub fn newEntity(self: *Self, gpa: Allocator) !Id {
            if (self.free_ids.items.len > 0) {
                return self.free_ids.pop();
            } else {
                const old_max_id = self.max_id.int();
                self.max_id.add(128);
                for (old_max_id..self.max_id.int()) |id| {
                    try self.free_ids.append(gpa, @enumFromInt(id));
                }
                return newEntity();
            }
        }

        pub fn set(self: *Self, id: Id, tag: []const u8, value: anytype) !void {
            assertTypeAccepted(@TypeOf(value), ComponentTypesTuple);

            const hashmap = @field(self.components, @typeName(@TypeOf(value)));
            const sset = hashmap.get(tag);
            const component = sset.get(id);
            _ = component; // autofix
        }
    };
}

//pub fn DeriveSparseSets(comptime Components: type) type {
//    const len = @typeInfo(Components).@"struct".decls.len;
//    var fields: [len]std.builtin.Type.StructField = undefined;
//
//    inline for (@typeInfo(Components).@"struct".decls, 0..) |decl, i| {
//        const ComponentType = @field(Components, decl.name);
//        //const default = SparseSet(ComponentType, IdBackingInt){};
//        var buf: [128]u8 = .{0} ** 128;
//        fields[i] = .{
//            .name = std.fmt.bufPrintZ(&buf, "{}", .{i}) catch unreachable,
//            .type = SparseSet(ComponentType, IdBackingInt),
//            .default_value = null, //?@as(*const SparseSet(ComponentType, IdBackingInt), &default),
//            .is_comptime = false,
//            .alignment = 8,
//        };
//    }
//
//    return @Type(.{
//        .@"struct" = .{
//            .layout = .auto,
//            .is_tuple = true,
//            .fields = &fields,
//            .decls = &.{},
//        },
//    });
//}
//
//pub fn ComponentUnion(comptime Components: type) type {
//    const len = @typeInfo(Components).@"struct".decls.len;
//    var fields: [len]std.builtin.Type.UnionField = undefined;
//
//    inline for (@typeInfo(Components).@"struct".decls, 0..) |decl, i| {
//        const ComponentType = @field(Components, decl.name);
//        fields[i] = .{
//            .name = decl.name,
//            .type = ComponentType,
//            .alignment = 0,
//        };
//    }
//
//    return @Type(.{
//        .@"union" = .{
//            .layout = .auto,
//            .tag_type = std.meta.DeclEnum(Components),
//            .fields = &fields,
//            .decls = &.{},
//        },
//    });
//}
//
///// Components should be a struct, every decl type will become a component
//pub fn Ecs(comptime Components: type) type {
//    return struct {
//        pub const Tag = std.meta.DeclEnum(Components);
//        pub const Component = ComponentUnion(Components);
//        components: DeriveSparseSets(Components),
//
//        pub fn setComponent(
//            self: *@This(),
//            gpa: std.mem.Allocator,
//            id: Id,
//            component: Component,
//        ) !void {
//            const tag = @intFromEnum(std.meta.activeTag(component));
//            _ = tag; // autofix
//
//            switch (component) {
//                inline 0...(@typeInfo(Tag).@"enum".fields.len - 1) => |tagged| {
//                    //std.debug.print("{any}", .{value});
//                    try self.components[tagged].set(
//                        gpa,
//                        @intFromEnum(id),
//                        component,
//                    );
//                },
//                else => unreachable,
//            }
//            //std.debug.print("{}: {any}", .{ std.meta.activeTag(component), self.components[tagged] });
//
//            //inline for (self.components, 0..) |set, i| {
//            //    if (tag == i) {
//            //        std.debug.print("{any}", .{set});
//            //    }
//            //}
//
//            //std.debug.print("{any}", .{self.components[tag]});
//
//            //const component_tag = @intFromEnum(std.meta.activeTag(component));
//            //inline for (@typeInfo(Tag).@"enum".fields) |field| {
//            //    //if(
//            //    if (component_tag == @intFromEnum(@field(Tag, field.name))) {
//            //        @field(self.fields,
//            //    }
//            //}
//            //const value = @field(component, @tagName(tag));
//            //std.debug.print("active_tag: {any}\n", .{tag});
//            //@field(self.components, @tagName(std.meta.activeTag(component))) = value;
//
//            //self.components[@intFromEnum(Tag)].set(
//            //try self.setComponentInternal(id, tag, std.mem.asBytes(value));
//        }
//    };
//}
//
//test "ecs" {
//    const T = Ecs(@import("components.zig"));
//    var ecs = T{ .components = undefined };
//    try ecs.setComponent(std.testing.allocator, @enumFromInt(0), .{ .Notes = .{} });
//    //T =
//    //std.debug.print("hi", .{});
//}
