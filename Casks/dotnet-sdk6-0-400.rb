cask "dotnet-sdk6-0-400" do
  arch arm: "arm64", intel: "x64"

  version "6.0.406,6.0.14"

  sha256_x64 = "75df4b691aec4d1645791643a9bd45b9aa11cc0d34b97a664e9a59bbf535e0fc"
  sha256_arm64 = "7197befb07840977815e47460b3eaf1d5043f9ecbf2ce822330cd79fc66ea8d2"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/85962c99-0139-47f0-aa4c-b566b809b6a1/2008bf2ed757e67f382fe92c0fcca583/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/a88e8808-bb19-4722-9101-a46814aa2118/17af8da06a520d9435038768fde4d085/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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
