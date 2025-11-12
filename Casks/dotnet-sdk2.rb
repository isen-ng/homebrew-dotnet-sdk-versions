cask "dotnet-sdk2" do
  version "2.2.402,2.2.7"
  sha256 :no_check

  url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/raw/master/META.md"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://github.com/isen-ng/homebrew-dotnet-sdk-versions"

  depends_on cask: "dotnet-sdk2-2-400"
  depends_on macos: ">= :sonoma"

  stage_only true
end
