const std = @import("std");

pub const Index = u64;
pub const max_capacity = std.math.maxInt(Index);

element_size_bytes: usize,
element_type_name: []const u8,
dense: []const u8,
sparse: []?Index,
dense_to_sparse_map: []?Index,
max_index: Index = max_capacity,

pub fn init(gpa: std.mem.Allocator, element_size_bytes: usize, element_type_name: []const u8) !@This() {
    _ = gpa; // autofix
    _ = element_size_bytes; // autofix
    _ = element_type_name; // autofix

}

//1:w
//
