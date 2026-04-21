# Spritz-Wine-TkG

`Spritz-Wine-TkG` is a custom Wine build aimed at making playing certain
anime games easier, without missing any of Wine's latest additions.

## Download

Spritz-Wine builds are available in all [an-anime-team](https://github.com/an-anime-team)'s launchers, but you can also download the latest version from the repository's [releases](https://github.com/NelloKudo/Wine-Builds/releases).

## Features:

- Fixes various issues with **certain anime games**, from launch issues to hanging on exit
- Rebased to **latest wine-staging**
- Bundles all **esync/fsync/ntsync** in the same build, with latter used by default if possible
- Includes many of Wine-TkG's fixes
- Backported and reworked many patches from Proton, mostly aiming controllers
- Includes some QoL fixes for dropping inputs, random crashes and alt-tabbing.

## Useful environmental variables

- Sync methods:
  - `WINENTSYNC=0`: disables NTsync, fallbacks to fsync
  - `WINEFSYNC=0`: disables fsync, fallbacks to esync

- Spritz patches:
  - `WINE_DISABLE_DISCONNECT=1`: disables the disconnecting trick when enabled by default
  - `WINE_ENABLE_DISCONNECT=1`: enables the disconnecting trick
  - `WINE_ENABLE_STEAM_STUB=1`: launches the executable using the `steam.exe` stub in the builds

- Proton imported patches:
  - `PROTON_PREFER_SDL=1`: uses SDL instead of hidraw, disabling it (already default)
  - `PROTON_DISABLE_HIDRAW=1`: disables hidraw (already default)
  - `PROTON_ENABLE_HIDRAW=1`: enables hidraw, fixes PlayStation glyphs not showing in some games

## Builds description

Spritz builds are built in a Docker container based on Proton's SDK, with a few changes you can see in the Dockerfile. The `wine-builder` container is hosted [here](https://hub.docker.com/r/nellokudo/wine-builder), built from its apposite [GitHub repository](https://github.com/NelloKudo/winebuilder-image).

Many thanks to spectator's work in the main repository for the polished building process.