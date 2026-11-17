cask "macmusicblock" do
  version "1.0.1"
  sha256 "ddec36e8569ffc6ae4197d49893c8190e3b9c4a825052d2d677e07c7ddf41677"

  url "https://github.com/henrikhestnes/MacMusicBlock/releases/download/v#{version}/MacMusicBlock.zip"
  name "MacMusicBlock"
  desc "Menu bar app that stops Apple Music from opening"
  homepage "https://github.com/henrikhestnes/MacMusicBlock"

  depends_on macos: :ventura

  app "MacMusicBlock.app"

  uninstall quit: "io.macmusicblock.app"

  zap trash: "~/Library/Preferences/io.macmusicblock.app.plist"

  caveats <<~EOS
    This build is signed with a self-signed certificate and has not been notarized by Apple.
  EOS
end
