# Spritz-Wine-CachyOS

`Spritz-Wine-CachyOS` is a custom Wine build aimed at making playing certain
anime games easier, without missing any of Wine's latest additions.

## Download

Spritz-Wine builds are available in all [an-anime-team](https://github.com/an-anime-team)'s launchers, but you can also download the latest version from the repository's [releases](https://github.com/NelloKudo/Wine-Builds/releases).

## Features:

- Fixes various issues with **certain anime games**, from launch issues to hanging on exit
- Rebased to **latest wine-cachyos**
- Bundles all **esync/fsync/ntsync** in the same build, with latter used by default if possible
- Includes some QoL fixes for dropping inputs, random crashes and alt-tabbing.
- Includes some backports from upstream Wine

## Useful environmental variables

- Sync methods:
  - `WINENTSYNC=0`: disables NTsync, fallbacks to fsync
  - `WINEFSYNC=0`: disables fsync, fallbacks to esync
  - `WINEESYNC=0`: disables esync, fallbacks to server sync

- Spritz patches:
  - `WINE_DISABLE_DISCONNECT=1`: disables the disconnecting trick when enabled by default
  - `WINE_ENABLE_DISCONNECT=1`: enables the disconnecting trick
  - `WINE_ENABLE_STEAM_STUB=1`: launches the executable using the `steam.exe` stub in the builds
  - `WINE_ENABLE_USE_TAKE_FOCUS=1`: re-enables UseTakeFocus, to use if having issues with tabbing

- Proton controllers:
  - `PROTON_DISABLE_HIDRAW=1`: disables hidraw, might fix issues with controllers on Xbox
  - `PROTON_ENABLE_HIDRAW=1`: enables hidraw, fixes PlayStation glyphs not showing in some games (default)

## Builds description

Spritz builds are built in a Docker container based on Proton's SDK, with a few changes you can see in the Dockerfile. The `wine-builder` container is hosted [here](https://hub.docker.com/r/nellokudo/wine-builder), built from its apposite [GitHub CI](https://github.com/NelloKudo/WineBuilder/actions/workflows/dockerhub.yml) from my main repository of [WineBuilder](https://github.com/NelloKudo/WineBuilder).

Many thanks to spectator's work in the main repository for the polished building process.