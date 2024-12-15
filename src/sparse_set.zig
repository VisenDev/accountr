const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

fn maxBit(num: u64) u64 {
    if (num == 0) return 0;
    return std.math.log2_int(num) + 1;
}

pub fn ArrayIndex(comptime BackingInt: type) type {
    return struct {
        pub const Sparse = enum(BackingInt) {
            _,
            //pub fn jsonStringify(
        };

        pub const Dense = enum(BackingInt) {
            _,
        };
    };
}

pub fn SparseSet(comptime T: type, comptime BackingInt: type) type {
    //
    return struct {
        pub const Index = ArrayIndex(BackingInt);

        dense_to_sparse_map: []Index.Sparse = &[_]Index.Sparse{},
        dense: []T = &[_]T{},
        dense_fill_count: BackingInt = 0,
        sparse: []?Index.Dense = &[_]?Index.Dense{},

        pub fn init() @This() {
            return .{};
        }

        pub fn deinit(self: *@This(), gpa: std.mem.Allocator) void {
            gpa.free(self.dense_to_sparse_map);
            gpa.free(self.dense);
            gpa.free(self.sparse);
        }

        pub fn expandSparse(self: *@This(), gpa: std.mem.Allocator, new_capacity: usize) !void {
            const old_len = self.sparse.len;
            self.sparse = try gpa.realloc(self.sparse, new_capacity);
            @memset(self.sparse[old_len..new_capacity], null);
        }

        pub fn expandDense(self: *@This(), gpa: std.mem.Allocator, new_capacity: usize) !void {
            const old_len = self.dense.len;
            self.dense = try gpa.realloc(self.dense, new_capacity);
            self.dense_to_sparse_map = try gpa.realloc(self.dense_to_sparse_map, new_capacity);
            @memset(std.mem.asBytes(self.dense[old_len..new_capacity]), 0);
            @memset(std.mem.asBytes(self.dense_to_sparse_map[old_len..new_capacity]), 0);
        }

        fn appendDense(self: *@This(), gpa: std.mem.Allocator, sparse_index: Index.Sparse, value: T) !Index.Dense {
            if (self.dense_fill_count + 1 >= self.dense.len) {
                try self.expandDense(gpa, self.dense.len * 2);
            }
            self.dense[self.dense_fill_count] = value;
            self.dense_to_sparse_map[self.dense_fill_count] = sparse_index;
            self.dense_fill_count += 1;
            return @enumFromInt(self.dense_fill_count - 1);
        }

        fn setDense(self: *@This(), sparse_index: Index.Sparse, index: Index.Dense, value: T) void {
            self.dense[@intFromEnum(index)] = value;
            self.dense_to_sparse_map[@intFromEnum(index)] = sparse_index;
        }

        fn setSparse(self: *@This(), sparse_index: Index.Sparse, value: ?Index.Dense) void {
            self.sparse[@intFromEnum(sparse_index)] = value;
        }

        /// Can clobber existing values
        pub fn set(self: *@This(), gpa: std.mem.Allocator, raw_index: BackingInt, value: T) !void {
            self.audit();
            defer self.audit();

            const index: Index.Sparse = @enumFromInt(raw_index);

            const capacity_needed: BackingInt = @intFromEnum(index) + 1;
            if (self.sparse.len < capacity_needed) {
                try self.expandSparse(gpa, capacity_needed);
            }

            const maybe_dense_index: ?Index.Dense = self.sparse[@intFromEnum(index)];
            if (maybe_dense_index) |dense_index| {
                self.setDense(index, dense_index, value);
            } else {
                const new_sparse_value: Index.Dense = try self.appendDense(gpa, index, value);
                self.setSparse(index, new_sparse_value);
            }
        }

        pub fn setNoClobber(self: *@This(), a: std.mem.Allocator, raw_index: BackingInt, value: T) !void {
            assert(self.getSparse(@enumFromInt(raw_index)) == null);
            try self.set(a, raw_index, value);
        }

        pub fn delete(self: *@This(), raw_index: BackingInt) !void {
            self.audit();
            defer self.audit();
            const index: Index.Sparse = @enumFromInt(raw_index);

            const maybe_dense_index = self.getSparse(index);

            if (maybe_dense_index) |dense_index| {
                self.setSparse(index, null);

                const top_value: T = self.dense[self.dense_fill_count - 1];
                const top_sparse_index: Index.Sparse = self.dense_to_sparse_map[self.dense_fill_count - 1];

                if (index != top_sparse_index) {
                    self.setDense(top_sparse_index, dense_index, top_value);
                    self.setSparse(top_sparse_index, dense_index);
                }

                self.dense_fill_count -= 1;
            }
        }

        fn getSparse(self: *const @This(), sparse_index: Index.Sparse) ?Index.Dense {
            const index: BackingInt = @intFromEnum(sparse_index);
            if (index < self.sparse.len) {
                return null;
            } else {
                return self.sparse[index];
            }
        }

        pub fn get(self: *const @This(), sparse_index: Index.Sparse) ?T {
            const maybe_dense_index: ?Index.Dense = self.getSparse(sparse_index);
            if (maybe_dense_index) |dense_index| {
                return self.dense[@intFromEnum(dense_index)];
            } else {
                return null;
            }
        }

        pub fn slice(self: *const @This()) []T {
            return self.dense;
        }

        pub fn audit(self: *const @This()) void {
            if (builtin.mode != .Debug) return;
            if (true) return;

            var non_null_count: usize = 0;
            for (self.sparse.items) |maybe_index| {
                if (maybe_index) |dense_index| {
                    //std.debug.print("dense_index: {}\n", .{dense_index});
                    //assert index points to a valid dense index
                    assert(dense_index >= 0);
                    assert(dense_index < self.dense.items.len);

                    non_null_count += 1;
                }
            }
            //assert that the number of non-nil sparse values equal the dense len
            assert(non_null_count == self.dense.items.len);

            //assert every dense_to_sparse mapping is valid
            for (self.dense_to_sparse_map, 0..) |sparse_index, dense_index| {
                assert(sparse_index >= 0);
                assert(sparse_index < self.sparse.items.len);
                assert(self.sparse.items[sparse_index] != null);
                assert(self.sparse.items[sparse_index].? == dense_index);
            }
        }
    };
}

test "sparse_set" {
    const a = std.testing.allocator;

    var set = SparseSet(usize, u8).init();
    defer set.deinit(a);
    try set.setNoClobber(a, 0, 12);
    try set.setNoClobber(a, 3, 13);
    try set.setNoClobber(a, 5, 14);
    try set.setNoClobber(a, 7, 15);
    try set.delete(0);
    try set.setNoClobber(a, 1, 16);
    try set.setNoClobber(a, 0, 17);

    try set.setNoClobber(a, 100, 16);
    try set.setNoClobber(a, 19, 17);
    try set.setNoClobber(a, 127, 17);
    try set.delete(100);
    try set.delete(19);
    try set.setNoClobber(a, 9, 17);
    try set.delete(9);
    try set.delete(127);
}

test "stringify" {
    const a = std.testing.allocator;
    var set = SparseSet(usize, u8).init();
    defer set.deinit(a);

    try set.setNoClobber(a, 0, 12);
    try set.setNoClobber(a, 3, 13);
    try set.setNoClobber(a, 5, 14);

    const string = try std.json.stringifyAlloc(a, set, .{});
    defer a.free(string);
    const parsed = try std.json.parseFromSlice(@TypeOf(set), a, string, .{});
    defer parsed.deinit();

    std.debug.print("hi", .{});
}
