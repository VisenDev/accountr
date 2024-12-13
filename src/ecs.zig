const std = @import("std");
const SparseSet = @import("sparse_set.zig").SparseSet;

/// A unique id
pub const Id = enum(u64) {
    _,
};

/// Tag for component type
pub const Tag = []const u8;

//components: std.ArrayListUnmanaged(SparseSet();
//
pub const Ecs = struct {
    pub fn setComponentInternal(self: *@This(), id: Id, tag: Tag, bytes: []const u8) !void {
        _ = self; // autofix
        _ = id; // autofix
        _ = tag; // autofix
        _ = bytes; // autofix

    }

    pub fn setComponent(self: *@This(), id: Id, tag: Tag, value: anytype) !void {
        try self.setComponentInternal(id, tag, std.mem.asBytes(value));
    }
};
