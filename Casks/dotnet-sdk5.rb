cask "dotnet-sdk5" do
  version "5.0.408,5.0.17"
  url "https://raw.githubusercontent.com/fluffynuts/homebrew-dotnet-sdk-versions/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"
  depends_on cask: "dotnet-sdk5-0-400"
  depends_on macos: ">= :high_sierra"
end
