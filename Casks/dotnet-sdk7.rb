cask "dotnet-sdk7" do

  arch arm: "arm64", intel: "x64"

  version "7.0.406,7.0.16"

  url = "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"
  sha256 = "93c1654aae5d0217e15ccd135433295b6840254e96db32324988f52f22ebb034"

  name ".NET Core SDK #{version.csv.first}"

  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"

  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk7-0-400"
  depends_on macos: ">= :mojave"

  stage_only true
end
