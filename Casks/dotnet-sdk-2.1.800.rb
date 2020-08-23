cask "dotnet-sdk-2.1.800" do
  version "2.1.809,2.1.21"
  sha256 "9c6e564cd18c58bfafa1a2b9b98b1d8d9a2a230c9e3e44f31823f4a594d92e1d"

  url "https://download.visualstudio.microsoft.com/download/pr/1ece43a4-f3e2-4c2d-8423-644d49aae7af/37def46eae1c1ed47e64f9e349ff9aaa/dotnet-sdk-2.1.809-osx-x64.pkg"
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
