# kosm_cs2

Counter-Strike 2 for kosm: one font for the game's Panorama UI. The app writes the game's
global fontconfig replacements file, `42-repl-global.conf`, with two rules per replaced family:
one for fonts already chosen (`assign`) and one for requests (`prepend`, strong binding).

The file belongs to the game: Steam may restore it when it verifies or updates the game, so
apply again afterwards. Restart the game to see the change.

`from(theme)` leaves the font alone, since a theme holds no fonts; set `font` in the kosmos.

## Fields

| Field | Default |
|---|---|
| `file` | `~/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/core/panorama/fonts/conf.d/42-repl-global.conf`; set it for another Steam library |
| `font` | the family replacing every one of `replaced`; null writes nothing |
| `replaced` | Stratum2, Stratum2 Bold, Arial, Times New Roman, Courier New, notosans, notoserif, notomono-regular, noto |
