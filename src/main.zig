const std = @import("std");
const ray = @import("raylib-import.zig").ray;
const dvui = @import("dvui");
const RaylibBackend = dvui.backend;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .retain_metadata = true,
        .enable_memory_limit = true,
        .verbose_log = true,
    }){};
    defer _ = gpa.detectLeaks();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const a = arena.allocator();

    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE);
    ray.SetConfigFlags(ray.FLAG_VSYNC_HINT); //disable this flag to test max fps
    ray.InitWindow(800, 450, "accountr");
    ray.SetTargetFPS(60);
    defer ray.CloseWindow();

    var dvui_backend = RaylibBackend.init(a);
    defer dvui_backend.deinit();

    var ui = try dvui.Window.init(@src(), a, dvui_backend.backend(), .{});
    defer ui.deinit();

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();
        ray.ClearBackground(ray.Color{ .r = 0xaa, .g = 0xaa, .b = 0xaa });
    }
}

test "simple test" {}
