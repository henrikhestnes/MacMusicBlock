#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

# Keep compiler caches inside the project so builds work in restricted environments.
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
architectures=()
if [[ "${1:-}" == "--universal" ]]; then
  architectures=(--arch arm64 --arch x86_64)
fi
swift build -c release --disable-sandbox -debug-info-format none "${architectures[@]}"
bin_path=$(swift build -c release --disable-sandbox -debug-info-format none "${architectures[@]}" --show-bin-path)
app="$PWD/dist.noindex/MacMusicBlock.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
# Replace the executable instead of overwriting a binary that may be running.
cp "$bin_path/MacMusicBlock" "$app/Contents/MacOS/MacMusicBlock.new"
mv -f "$app/Contents/MacOS/MacMusicBlock.new" "$app/Contents/MacOS/MacMusicBlock"
cp Resources/Info.plist "$app/Contents/Info.plist"
swift scripts/make-icon.swift "$PWD/dist.noindex"
cp "$PWD/dist.noindex/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
# The hardened runtime enables library validation and ignores DYLD_* variables, so another process
# cannot inject code into the app. It works with an ad-hoc signature.
codesign --force --options runtime --sign - --identifier io.macmusicblock.app "$app"
ditto -c -k --sequesterRsrc --keepParent "$app" "$PWD/dist.noindex/MacMusicBlock.zip"
echo "Built: $app"
echo "Install: drag MacMusicBlock.app to Applications, then open it."
