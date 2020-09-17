cask "dotnet-sdk3-1-400" do
  version "3.1.402,3.1.8"
  sha256 "76c34d468e28ae3419186cc7711563b591c9d25dfa9a441960e56cc9af4bbe79"

  url "https://download.visualstudio.microsoft.com/download/pr/340e6cc2-cce5-44ad-aab6-012233d90aa7/265cf15bcbe10fb8445060f792e48bf9/dotnet-sdk-3.1.402-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  if MacOS.version > :sierra
    conflicts_with cask: [
      "dotnet",
      "dotnet-sdk",
    ]
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  binary "/usr/local/share/dotnet/dotnet"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
            delete:  [
              "/etc/paths.d/dotnet",
              "/etc/paths.d/dotnet-cli-tools",
            ]

  zap trash:   ["~/.dotnet", "~/.nuget"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
