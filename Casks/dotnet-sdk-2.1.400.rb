cask "dotnet-sdk-2.1.400" do
  version "2.1.403,2.1.5"
  sha256 "d290cefddb4fbdf1215724c049d86b4ce09f5dc2c5a658e3c1645c368f34c31a"

  url "https://download.visualstudio.microsoft.com/download/pr/38102737-cb48-46c2-8f52-fb7102b50ae7/d81958d71c3c2679796e1ecfbd9cc903/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
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