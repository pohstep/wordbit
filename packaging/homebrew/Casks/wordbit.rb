cask "wordbit" do
  version "2.2.0"

  sha256 "REPLACE_WITH_SHA256"
  url "https://github.com/pohstep/wordbit/releases/download/v#{version}/Wordbit-#{version}.dmg"

  name "Wordbit"
  desc "One new English word a day in the Mac menu bar"
  homepage "https://github.com/pohstep/wordbit"

  depends_on macos: ">= :ventura"

  app "Wordbit.app"

  uninstall quit: "com.pohstep.wordbit"

  zap trash: "~/Library/Application Support/Wordbit"

  caveats <<~EOS
    Wordbit is unsigned. The first time you open it, macOS says it cannot verify the app.
    macOS 15 or newer: allow it once with "Open Anyway" in System Settings → Privacy & Security.
    macOS 13–14: right-click the app and choose Open.
    Or, in Terminal: xattr -dr com.apple.quarantine "/Applications/Wordbit.app"
  EOS
end
