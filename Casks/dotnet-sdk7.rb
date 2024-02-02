cask "dotnet-sdk7" do
  arch arm: "arm64", intel: "x64"
  version "7.0.405,7.0.15"
  url "https://raw.githubusercontent.com/fluffynuts/homebrew-dotnet-sdk-versions/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"
  depends_on cask: "dotnet-sdk7-0-400"
  depends_on macos: ">= :mojave"
end
