cask "dotnet-sdk7-0-200" do
  arch arm: "arm64", intel: "x64"

  version "7.0.203,7.0.5"

  sha256_x64 = "82e6bfd3301d1b718e136fdaa1dd23d6abb03adbca05fcbc268b0da7e0d65b46"
  sha256_arm64 = "c80e0eabfa3681fa1db33c149ccbbb7de9155702aa5baaa11ea63f998151f326"

  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/08b3b509-05e6-4df1-84e1-a76c8855d899/d9b9a2d8ef9788f345d97304ceb67b07/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/a5070179-d53b-4a84-98d6-37a9d3ef458b/f8bba83817d23e3b7726746c59de4e0c/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_intel do
    sha256 sha256_x64
    url url_x64
  end
  on_arm do
    sha256 sha256_arm64
    url url_arm64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :mojave"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
