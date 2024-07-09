cask "dotnet-sdk6" do
  arch arm: "arm64", intel: "x64"

  version "6.0.424,6.0.32"
  sha256 :no_check

  url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/isen-ng/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk6-0-400"
  depends_on macos: ">= :mojave"

  stage_only true
end
