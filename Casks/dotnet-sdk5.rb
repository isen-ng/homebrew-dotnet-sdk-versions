cask "dotnet-sdk5" do
  version "5.0.408,5.0.17"
  sha256 :no_check

  url "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk5-0-400"
  depends_on macos: ">= :high_sierra"

  stage_only true
end
