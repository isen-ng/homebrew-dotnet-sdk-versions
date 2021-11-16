cask "dotnet-sdk5-0-200" do
  version "5.0.209,5.0.12"
  sha256 "45c68c1088309eed1a155bf8387af475df27620c835bda7346c2ca5d18c47d44"

  url "https://download.visualstudio.microsoft.com/download/pr/b1d592f4-0147-4c34-a92b-28743d36786e/ee939db82d1b0dbd248c40aa92971b84/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  postflight do
    FileUtils.ln_sf("/usr/local/share/dotnet/x64/dotnet", "#{HOMEBREW_PREFIX}/bin")
  end

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

  zap trash:   ["~/.dotnet", "~/.nuget"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.pack.apphost.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
