cask "dotnet-sdk6-0-100" do
  version "6.0.101,6.0.1"

  arch = Hardware::CPU.intel? ? "x64" : "arm64"
  sha256_x64 = "31414204e26119baf10eaa035ff1b30e98df1bd57c5d86800fd95c5a4b7caa20"
  sha256_arm64 = "429a2759df7adaba9c29ca4b4d1b4c3a7dc393b5f5238ab77d90203eced0fafd"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/83e6b9b3-a78e-4df7-b33f-78a38a1db0c7/b1641cad9024c212bafdd6273f3d5e19/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/43027810-8a5a-40bf-a10a-c3e8d9adef48/e11706837e6380a1760438d0787e9b72/dotnet-sdk-#{version.before_comma}-osx-arm64.pkg"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
