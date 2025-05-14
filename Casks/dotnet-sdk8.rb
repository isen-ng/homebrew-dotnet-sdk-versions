cask "dotnet-sdk8" do
  arch arm: "arm64", intel: "x64"

  version "8.0.409,8.0.16"
  sha256 :no_check

  url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/isen-ng/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk8-0-400"
  depends_on macos: ">= :catalina"

  stage_only true
end
