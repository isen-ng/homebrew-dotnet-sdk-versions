cask "dotnet-sdk7" do
  arch arm: "arm64", intel: "x64"

  sha256 :no_check
  version "7.0.406,7.0.16"
  url "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk7-0-400"
  depends_on macos: ">= :mojave"

  stage_only true
end
