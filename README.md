# MacMusicBlock

Stops Apple Music from opening, from the menu bar. Swift and AppKit, with no dependencies. Requires macOS 13 or newer.

macOS opens Apple Music when you press the play key with nothing playing, connect AirPods or other Bluetooth headphones, or open an audio file. MacMusicBlock quits Apple Music the moment it starts, and can open another player, such as Spotify, in its place.

## Install

```sh
brew install --cask henrikhestnes/tap/macmusicblock
```

Update with `brew update` and `brew upgrade --cask macmusicblock`. You can also download `MacMusicBlock.zip` from the [latest release](https://github.com/henrikhestnes/MacMusicBlock/releases/latest) and move **MacMusicBlock.app** to **Applications**. The release is ad-hoc signed and not notarized by Apple, so macOS may block it through Gatekeeper.

To build from source instead:

```sh
./scripts/build.sh
cp -R dist.noindex/MacMusicBlock.app /Applications/
open /Applications/MacMusicBlock.app
```

`./scripts/build.sh --universal` builds for both Apple silicon and Intel.

MacMusicBlock turns on **Launch at Login** the first time it runs. Turn it off from the menu bar icon; MacMusicBlock won't turn it back on. It needs no permissions.

## Menu

| Item | Effect |
| --- | --- |
| **Block Apple Music** | Pause or resume blocking. Resuming also quits Apple Music if it is open |
| **Open Instead** | Open another app whenever Apple Music is blocked, or nothing |
| **Launch at Login** | Start with your Mac |

To use Apple Music on purpose, untick **Block Apple Music** first.

## How it works

MacMusicBlock watches `NSWorkspace` launch notifications and force-quits any process with the bundle identifier `com.apple.Music` (or `com.apple.iTunes`), then opens the chosen replacement if it isn't already running. Apple Music may flash in the Dock for a moment. The launch policy lives in `MacMusicBlockCore` and is unit tested.

## Development

```sh
swift build
swift test
```
