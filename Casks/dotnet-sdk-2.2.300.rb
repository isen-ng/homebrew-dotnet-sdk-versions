cask "dotnet-sdk-2.2.300" do
  version "2.2.301,2.2.6"
  sha256 "5c39f1ed440d913206d471288100c0f1bc8429a3e53e51892df0a160aba2ff07"

  url "https://download.visualstudio.microsoft.com/download/pr/1440e4a9-4e5f-4148-b8d2-8a2b3da4e622/d0c5cb2712e51c188200ea420d771c2f/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  appcast "https://www.microsoft.com/net/download/macos"
  name ".NET Core SDK #{version.before_comma}"
  homepage "https://www.microsoft.com/net/core#macos"

  depends_on macos: ">= :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

  zap trash: [
    "~/.dotnet",
    "~/.nuget"
  ],
      pkgutil: [
        "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
        "com.microsoft.dotnet.hostfxr.#{version.after_comma.before_colon}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma.before_colon}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64"
      ]
end
