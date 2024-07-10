cask "dotnet-sdk6-0-400" do
  arch arm: "arm64", intel: "x64"

  version "6.0.424,6.0.32"

  sha256_x64 = "5e37fe1747490b30adc90fd59dce2a00caf635a447a8fb2952a8ba0a3469f903"
  sha256_arm64 = "e508a0f124b5c4cd7454621a60f35e716723f03686c9b85c4cfc7679ba0b5c16"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/0161ccc5-bb74-4d5f-b153-fb9ed1f31531/a3e393ab61522f4b8050cfd2692ad1d6/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/c88c088d-fdf3-46f2-bacb-64ea20d20d65/b751a812209385384ec32a3d84124200/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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

  zap pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ],
      trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
