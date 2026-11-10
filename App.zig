//! Counter-Strike 2's font: the game's Panorama UI families replaced by one font, in the
//! global replacements file its fontconfig reads (`42-repl-global.conf`).

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// The replacements file kosm owns. Default: the one in Steam's default library,
/// `~/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/core/panorama/fonts/conf.d/42-repl-global.conf`.
file: []const u8 = "~/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/core/panorama/fonts/conf.d/42-repl-global.conf",
/// The family every one of `replaced` becomes. null: the file is not written.
font: ?[]const u8 = null,
/// The game's families to replace. Default: Stratum2 and its bold, the Windows families it
/// falls back to (Arial, Times New Roman, Courier New) and its Noto fonts.
replaced: []const []const u8 = &.{ "Stratum2", "Stratum2 Bold", "Arial", "Times New Roman", "Courier New", "notosans", "notoserif", "notomono-regular", "noto" },

/// Leaves the font alone; a theme holds no fonts.
pub fn from(theme: kosm.Theme) App {
    _ = theme;
    return .{};
}

/// A fontconfig rule replacing one family, for fonts already chosen (`font`) and for
/// requests (`pattern`).
const Match = struct {
    @"@target": enum { font, pattern },
    @"test": Test,
    edit: Edit,
};

const Test = struct {
    @"@name": []const u8 = "family",
    string: []const u8,
};

const Edit = struct {
    @"@name": []const u8 = "family",
    @"@mode": enum { assign, prepend },
    @"@binding": enum { weak, strong },
    string: []const u8,
};

/// Writes a rule pair per replaced family. Without `font`, nothing is written.
pub fn apply(self: App, output: *kosm.Output) !void {
    const font = self.font orelse return;
    if (self.replaced.len == 0) return output.fail(self.file, "replaced lists no families; leave font null to keep the game's", .{});
    const matches = try output.allocator.alloc(Match, self.replaced.len * 2);
    for (self.replaced, 0..) |family, index| {
        matches[index * 2] = .{ .@"@target" = .font, .@"test" = .{ .string = family }, .edit = .{ .@"@mode" = .assign, .@"@binding" = .weak, .string = font } };
        matches[index * 2 + 1] = .{ .@"@target" = .pattern, .@"test" = .{ .string = family }, .edit = .{ .@"@mode" = .prepend, .@"@binding" = .strong, .string = font } };
    }
    try output.generate(.{ .file = self.file, .lang = "xml" }, .{
        .@"!DOCTYPE" = kosm.raw("fontconfig SYSTEM 'fonts.dtd'"),
        .fontconfig = .{ .match = matches },
    });
}

const testing = std.testing;
const adapter = @import("root.zig").xml_adapter;

const Fixture = struct {
    tmp: testing.TmpDir,
    arena: std.heap.ArenaAllocator,
    plan: kosm.Plan,
    diagnostics: kosm.Diagnostics = .{},
    warnings: kosm.Warnings = undefined,
    home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined,
    output: kosm.Output = undefined,

    fn init(fixture: *Fixture) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
        fixture.warnings = .init(fixture.arena.allocator());
        const length = try fixture.tmp.dir.realPath(testing.io, &fixture.home_buffer);
        fixture.output = .{
            .allocator = fixture.arena.allocator(),
            .home = fixture.home_buffer[0..length],
            .adapters = &.{adapter},
            .plan = &fixture.plan,
            .diagnostics = &fixture.diagnostics,
            .warnings = &fixture.warnings,
            .app = "cs2",
        };
    }

    fn deinit(fixture: *Fixture) void {
        fixture.plan.deinit();
        fixture.arena.deinit();
        fixture.tmp.cleanup();
    }
};

test "each replaced family gets a font rule and a pattern rule naming the font" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    const app: App = .{ .file = "~/42-repl-global.conf", .font = "Maple Mono", .replaced = &.{"Stratum2"} };
    try app.apply(&fixture.output);
    try testing.expectEqualStrings(
        \\<?xml version="1.0"?>
        \\<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        \\<fontconfig>
        \\  <match target="font">
        \\    <test name="family">
        \\      <string>Stratum2</string>
        \\    </test>
        \\    <edit name="family" mode="assign" binding="weak">
        \\      <string>Maple Mono</string>
        \\    </edit>
        \\  </match>
        \\  <match target="pattern">
        \\    <test name="family">
        \\      <string>Stratum2</string>
        \\    </test>
        \\    <edit name="family" mode="prepend" binding="strong">
        \\      <string>Maple Mono</string>
        \\    </edit>
        \\  </match>
        \\</fontconfig>
        \\
    , fixture.plan.files.items[0].new);
}

test "without a font nothing is written, and an empty replaced list fails" {
    var fixture: Fixture = undefined;
    try fixture.init();
    defer fixture.deinit();
    try from(kosm.Theme.from(.{ .black = kosm.hex("000000"), .white = kosm.hex("ffffff") }, .dark)).apply(&fixture.output);
    try testing.expectEqual(0, fixture.plan.files.items.len);
    const empty: App = .{ .font = "Maple Mono", .replaced = &.{} };
    try testing.expectError(error.AppFailed, empty.apply(&fixture.output));
}
