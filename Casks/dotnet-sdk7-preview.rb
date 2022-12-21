cask "dotnet-sdk7-preview" do
  arch arm: "arm64", intel: "x64"

  version "7.0.100-preview.7.22377.5,7.0.0-preview.7.22375.6"

  sha256_x64 = "d37cd53a737ff1c05310e3e71dcee260b17196476b9c8c4bfa5bb3ac8b6d06a9"
  sha256_arm64 = "dd2cac1674c8208c9bfe9735833d18cabd57e116b998133c14e1eb3bd7251816"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/c4688e7c-6076-4e7c-bc8d-99ff138f91ce/059f21d41a3e06aeba8ef02d465887ab/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/064356b7-bf90-4c32-bfa9-f5acad1b24fb/dafa5b5f0b7c57d851f5af4d78db2f61/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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
