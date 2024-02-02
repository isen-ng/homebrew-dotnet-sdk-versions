cask "dotnet-sdk6" do
  arch arm: "arm64", intel: "x64"
  version "6.0.418,6.0.26"
  url "https://raw.githubusercontent.com/fluffynuts/homebrew-dotnet-sdk-versions/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"
  depends_on macos: ">= :mojave"
  depends_on cask: "dotnet-sdk6-0-400"
  depends_on macos: ">= :mojave"
end
