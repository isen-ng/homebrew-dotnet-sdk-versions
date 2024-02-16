cask "dotnet-sdk2" do

  version "2.1.818,2.1.30"

  url "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions/raw/master/META.md"
  sha256 :no_check

  name ".NET Core SDK #{version.csv.first}"

  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"

  homepage "https://github.com/fluffynuts/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk2-1-800"
  depends_on macos: ">= :sierra"

  stage_only true
end
