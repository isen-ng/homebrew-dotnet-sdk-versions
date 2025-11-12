cask "dotnet-sdk8-preview" do
  arch arm: "arm64", intel: "x64"

  version "8.0.100-rc.2.23502.2,8.0.0-rc.2.23479.6"

  sha256_x64 = "9d5005eb918efa39fc77d944533a4e9ad2818bcf76a89300e9fd8d6da4130a21"
  sha256_arm64 = "7cd67cbca1529d51460c752b3821f61f688c8d3d1ca225bd2bb4341d32c34675"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/69d7c726-56c4-4652-94e5-4e10a5ac846f/4ef542bc620666656a74d0f6e2235fb8/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/0e35f353-a3c0-4fe5-9f8c-9db472d07f50/ae1ad30cfc182e4d7766b2bf4a063097/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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

  depends_on macos: ">= :sonoma"

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
