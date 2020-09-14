cask "dotnet-sdk-2.1.500" do
  version "2.1.518,2.1.22"
  sha256 "dd570e5793627f8e17edccfcbf3d75391d4a9704b1060da4ba94d9065b557eed"

  url "https://download.visualstudio.microsoft.com/download/pr/95486566-6122-44a9-bc1f-c6144f69fa2f/b67c569f875bc0b1aa0b386f36533de5/dotnet-sdk-2.1.518-osx-x64.pkg"
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
