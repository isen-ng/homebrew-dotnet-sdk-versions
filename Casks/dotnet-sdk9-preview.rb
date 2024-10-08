cask "dotnet-sdk9-preview" do
  arch arm: "arm64", intel: "x64"

  version "9.0.100-rc.2.24474.11,9.0.0-rc.2.24473.5"

  sha256_x64 = "9e4a019acb3bd4b70ff8ac44d85d9f1d978657df750d4a9710d417d7f2981619"
  sha256_arm64 = "dd730a97f2781dcd1d474501b854838580332c2e52a9cfa90fcd87d3f99c36fd"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/71285611-e6d6-4758-8a5b-fec2b48fa25b/4aaf5fe8828150531679788c418a5920/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/2d099a55-d6f5-43f8-bf05-fe90f023554d/03b79d057c06c1ae0855c8e8c5696680/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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

  depends_on macos: ">= :monterey"

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
