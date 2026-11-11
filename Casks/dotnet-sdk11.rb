cask "dotnet-sdk11" do
  arch arm: "arm64", intel: "x64"

  version "11.0.100,11.0.0"
  sha256 :no_check

  url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/isen-ng/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk11-0-100"
  depends_on macos: :any

  stage_only true
end
