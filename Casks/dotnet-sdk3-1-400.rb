cask "dotnet-sdk3-1-400" do
  version "3.1.407,3.1.13"
  sha256 "e65bd0a99365d494a07983f33346597db220dc3e199acc1aedde3dd0d3795750"

  url "https://download.visualstudio.microsoft.com/download/pr/ecd4efe6-5f37-4183-82a1-dd2de88ca573/144bb23aab65c4439d0600973d756e6b/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  depends_on macos: "> :sierra"

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
