cask "dotnet-sdk3-1-400" do
  version "3.1.405,3.1.11"
  sha256 "704f0c2762c58bead9c2b9107b73831d12fdc1d4514cba0b68474f3247316bb6"

  url "https://download.visualstudio.microsoft.com/download/pr/c447be5f-eb7c-49c8-8588-b36172371fed/99b706d3682c44fb0dc86bffdc428782/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
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
