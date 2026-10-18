cask "wordbit" do
  version "2.1.0"

  # url and sha256 are placeholders until the v2.1.0 release .dmg exists.
  # Replace sha256 with: shasum -a 256 Wordbit-2.1.0.dmg
  sha256 "PLACEHOLDER_SHA256_OF_WORDIT_2_1_0_DMG"
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
    Allow it once with "Open Anyway" in System Settings → Privacy & Security.
    Or, in Terminal: xattr -dr com.apple.quarantine "/Applications/Wordbit.app"
  EOS
end
