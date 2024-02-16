cask "dotnet-sdk8" do

  arch arm: "arm64", intel: "x64"

  version "8.0.101,8.0.1"

  url "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"
  sha256 :no_check

  name ".NET Core SDK #{version.csv.first}"

  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"

  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk8-0-100"
  depends_on macos: ">= :catalina"

  stage_only true
end
