cask "dotnet-sdk6" do
  arch arm: "arm64", intel: "x64"

  sha256 :no_check
  version "6.0.419,6.0.27"
  url "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk6-0-400"
  depends_on macos: ">= :mojave"

  stage_only true
end
