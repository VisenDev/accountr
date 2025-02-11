const std = @import("std");
const Id = @import("ecs.zig").Id;

/// contact info
pub const Contact = struct {
    email: []const u8,
    cell_phone_number: ?[10]u8 = null,
    work_phone_number: ?[10]u8 = null,
};

/// Information about a person
pub const PersonName = struct {
    first_name: []const u8,
    middle_name: []const u8 = "",
    last_name: []const u8,
    //email: []const u8,
    //cell_phone_number: ?[10]u8 = null,
    //work_phone_number: ?[10]u8 = null,
    //employer: ?Id = null,
};

/// Information about one of our customers (usually businesses)
pub const Customer = struct {
    name: []const u8,
    address: []const u8,
    contacts: []Id,
    orders: []Id,
};

/// Information about an order
pub const Order = struct {
    customer: Id,
    parts: []Id,
};

/// Whether or not an entity is active
pub const StateActive = struct {};

/// Whether or not an entity is archived
pub const StateArchived = struct {};

/// A timestamp metadata about an entity
pub const TimeStamp = struct {
    created: i64,
    modified: i64,
    accessed: i64,
};

/// User metadata about an entity
pub const UserLog = struct {
    created_by: Id,
    modified_by: Id,
    accessed_by: Id,
};

/// Any additional notes about an entity
pub const Notes = struct {
    //items: []const u8 = ,
};

/// Flag for a part
pub const IsPart = struct {
    customer: Id,
};

pub const Image = struct {
    png: []const u8,
};

/// A price
pub const Price = struct {
    dollars: u32,
    cents: u8,
};
