cask "dotnet-sdk7-0-300" do
  arch arm: "arm64", intel: "x64"

  version "7.0.306,7.0.9"

  sha256_x64 = "129c927b3e0446bec06583f659d2f6681e6551b2ef7c7f258bc0b3ca97b7c214"
  sha256_arm64 = "50a412b0e7e4da20d846de5afe17ea0874697db044b049ab2021eef8824e6b34"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/534a66a3-31a4-4cf7-9866-319414f5876d/f6e644cc2bdcab7801efef1c533e8400/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/4cfe3db4-4922-404d-b2de-db478a9a6c4a/5ec100c639e38cac64a61a02c9ab4df7/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
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
