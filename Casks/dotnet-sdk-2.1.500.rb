cask "dotnet-sdk-2.1.500" do
  version "2.1.516,2.1.20"
  sha256 "3565e1f7314a4cb7277c025a8ae7652ee9d0cca6fdc3c0a3330af50dee2af148"

  url "https://download.visualstudio.microsoft.com/download/pr/3430b27f-f317-4736-a078-63b020936f92/b1fe7fd7e25ca936a7a82b29b065c4f9/dotnet-sdk-2.1.516-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  homepage "https://www.microsoft.com/net/core#macos"

  depends_on macos: ">= :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

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
