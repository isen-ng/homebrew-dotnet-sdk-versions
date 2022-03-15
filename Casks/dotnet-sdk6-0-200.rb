cask "dotnet-sdk6-0-200" do
  version "6.0.201,6.0.3"

  arch = Hardware::CPU.intel? ? "x64" : "arm64"
  sha256_x64 = "a6199cee00bb381b00847cf2e4e7a2192935e2a03c8892a3368a5b3479f3868f"
  sha256_arm64 = "a219339edb3156c84bfc684efc5a1061d528b2e10b870763bb1119f925249135"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/a5e0f5da-6088-451c-a341-b751c0d418c7/9fe3a31273888fe23cbe71cac32fa35c/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/2e20d654-1371-4c8f-a0dd-e81bac07549e/7b63667ab1941110bf9e684dc66b590d/dotnet-sdk-#{version.before_comma}-osx-arm64.pkg"

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

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
