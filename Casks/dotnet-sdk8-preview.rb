cask "dotnet-sdk8-preview" do
  arch arm: "arm64", intel: "x64"

  version "8.0.100-rc.1.23463.5,8.0.0-rc.1.23419.4"

  sha256_x64 = "29d9f6b0263f7df03f5d3d37e54345bd8cb89ad711a7dba32e691f86af8d62c7"
  sha256_arm64 = "f30cc0fd0ab9a3864c05befaf0d5b58bbe4169c15c5b3e35a14ce3e684d01e79"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/a1c8239d-f1fd-4b47-be6b-e07217068e46/78337c7ab38ad4cf0f4ed2db5f7ebe66/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/030ab62d-61c2-4f8f-bcec-ee45837f7df0/f69ba0e33588a4fa6a41e7b56cd52654/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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
