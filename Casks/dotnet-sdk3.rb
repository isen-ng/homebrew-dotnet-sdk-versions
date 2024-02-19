cask "dotnet-sdk3" do
  version "3.1.426,3.1.32"
  sha256 :no_check

  url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/isen-ng/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk3-1-400"
  depends_on macos: ">= :high_sierra"

  stage_only true
end
