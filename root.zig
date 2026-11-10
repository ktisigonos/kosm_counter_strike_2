//! Counter-Strike 2: one font for its Panorama UI, through the game's fontconfig replacements.

const std = @import("std");

/// The font replacements; build one with `from`.
pub const App = @import("App.zig");
/// The app with the game's fonts left alone; a theme holds no fonts.
pub const from = App.from;
/// The adapter the app writes its file with, so a config needs only this package.
pub const xml_adapter = @import("kosm_xml").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
