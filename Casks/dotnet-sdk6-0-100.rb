cask "dotnet-sdk6-0-100" do
  version "6.0.102,6.0.2"

  arch = Hardware::CPU.intel? ? "x64" : "arm64"
  sha256_x64 = "09e5bf1946b3892cc9f3bcba495e0524b849e006900332e0f58baeca8498121a"
  sha256_arm64 = "9222af1505b3698c2cc929110b4b068ad99ede3291c4e365dc8c59c6b0c0d5c9"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/8509554d-61b4-43b8-b934-ad2e679ce18f/aa565a52b909b3133ef6763bb2868a49/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/cc2a94b1-7f3c-44f8-a842-f288a0cff04e/32446a93655522a1f933d4afb5e15836/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
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
          "so you\'ll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
