cask "dotnet-sdk3" do

  version "3.1.426,3.1.32"

  url = "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"
  sha256 = "93c1654aae5d0217e15ccd135433295b6840254e96db32324988f52f22ebb034"

  name ".NET Core SDK #{version.csv.first}"

  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"

  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk3-1-400"
  depends_on macos: ">= :high_sierra"

  stage_only true
end
