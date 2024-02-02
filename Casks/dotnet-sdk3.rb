cask "dotnet-sdk3" do
  version "3.1.426,3.1.32"
  url "https://raw.githubusercontent.com/fluffynuts/homebrew-dotnet-sdk-versions/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"
  depends_on cask: "dotnet-sdk3-1-400"
  depends_on macos: ">= :high_sierra"
end
