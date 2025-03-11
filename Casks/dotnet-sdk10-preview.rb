cask "dotnet-sdk10-preview" do
  arch arm: "arm64", intel: "x64"

  version "10.0.100-preview.1.25120.13"

  sha256_x64 = "29900a2b93424661ba0300671be017629ca5c5183cdddbeaecae2666f8a5ea6c26e415b7f2286a6644efa27523ebb0f61080b9fad82f85dc9c648344af36268d"
  sha256_arm64 = "14f83d81cbafcc572a70100037c677911368970e4b20dd471d69595813b688615577b393cb4f8579b284493341b7642ad2f2d00171dd9d1d40d35e886e2ed2dc"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/80339095-1418-4792-9d81-d7b8dc44a436/d8f1d068666055023d1c98e6d4f8fd60/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/a826c444-678e-487e-8c4e-ebfc14afca99/d22a35c78682369beb65d20afc995a7e/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
  end

  name ".NET SDK #{version.csv.first}"
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
