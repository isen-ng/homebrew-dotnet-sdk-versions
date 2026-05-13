cask "dotnet-sdk11-preview" do
  arch arm: "arm64", intel: "x64"

  version "11.0.100-preview.4.26230.115,11.0.0-preview.4.26230.115"

  sha256_x64 = "9fa751346682347cd5c06ef43a1d1d7dd8a8c93acfe6af373e01718b43d3274b"
  sha256_arm64 = "8e53aee87cc090447e357311a26093de26414ebc948a313ebd7354c150fcf6e2"
  url_x64 = "https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version.csv.first}/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://builds.dotnet.microsoft.com/dotnet/Sdk/#{version.csv.first}/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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

  depends_on macos: :monterey

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ],
      trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"]

  caveats "Uninstalling the official dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
