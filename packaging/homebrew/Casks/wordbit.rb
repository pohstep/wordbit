cask "wordbit" do
  version "2.1.0"

  sha256 "14043ea0dad35a25752022083c632457bf8b94fb8e36b34d2af4d16e89de6100"
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
