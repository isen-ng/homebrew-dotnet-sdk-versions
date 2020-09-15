cask "dotnet-sdk-5.0.100" do
  version "5.0.100-rc.1.20452.10,5.0.0-rc.1.20451.14"
  sha256 "02a4954e933ef9bb782940f44ae83f8506589acb5605408a8ce67ecbe8628135"

  url "https://download.visualstudio.microsoft.com/download/pr/288c8d33-c0e0-4ab2-a9c0-7278f4e2490f/68c2c7c6e1d971d29caa12302e9352cf/dotnet-sdk-5.0.100-rc.1.20452.10-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  homepage "https://www.microsoft.com/net/core#macos"

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
            delete:  [
              "/etc/paths.d/dotnet",
              "/etc/paths.d/dotnet-cli-tools",
            ]

  zap trash:   ["~/.dotnet", "~/.nuget"],
      pkgutil: [
        "com.microsoft.dotnet.pack.targeting.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
        "com.microsoft.dotnet.pack.apphost.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you'll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
