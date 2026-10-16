# GlobalTools Legacy (optional client addon)

An optional WoW 3.3.5a client addon for `mod-legacy`. It turns the chat commands
(`.legacy`, `.legacy buy`, `.legacy reset`) into a small window with buttons, so
players can spend their account-wide Legacy Points without typing anything.

It is **optional**: the module works fine without it. Credit for the addon goes to
Yluyan / Carlos (see PR #2).

## Two ways to run, no setup

- **With the GlobalTools hub installed**: it plugs itself in as a "Legacy System"
  tab, adds a dropdown-menu category and syncs with `/gt sync`.
- **Without the hub**: it opens its own window with `/glegacy`.

## Languages

The addon is translated and picks the client's language automatically, falling
back to English for anything a language does not cover.

- English (`enUS`, base)
- German (`deDE`)
- Spanish (`esES` / `esMX`)
- French (`frFR`)

To add a language, copy the `enUS` block in `GlobalTools_Legacy/Locale.lua`, give it
the locale code (e.g. `ruRU`) and translate the values. You only need to translate
the keys you want; the rest falls back to English.

## Installation

1. Copy the folder `GlobalTools_Legacy` (the one next to this README) into your WoW
   client's `Interface/AddOns/` directory.
2. Make sure the folder is named exactly `GlobalTools_Legacy` (WoW requires the
   folder name to match the `.toc` file).
3. Restart the client, or `/reload`, and enable it in the AddOns list.

```
Interface/
  AddOns/
    GlobalTools_Legacy/
      GlobalTools_Legacy.toc
      Locale.lua
      Legacy.lua
```

## Commands

```
/glegacy        - open/close the window
/glegacy sync   - ask the server for your current points and ranks
/glegacy chat   - hide/show the server's Legacy chat replies
/glegacy help   - list the commands
```
