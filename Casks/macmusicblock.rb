cask "macmusicblock" do
  version "1.0.0"
  sha256 "0c47fd2e29aff1f31abb6d9f2cfa195dd69edc26bf36a0e0624cf8e64df4e2bd"

  url "https://github.com/henrikhestnes/MacMusicBlock/releases/download/v#{version}/MacMusicBlock.zip"
  name "MacMusicBlock"
  desc "Menu bar app that stops Apple Music from opening"
  homepage "https://github.com/henrikhestnes/MacMusicBlock"

  depends_on macos: :ventura

  app "MacMusicBlock.app"

  uninstall quit: "io.macmusicblock.app"

  zap trash: "~/Library/Preferences/io.macmusicblock.app.plist"

  caveats <<~EOS
    This build is ad-hoc signed and has not been notarized by Apple.
  EOS
end
