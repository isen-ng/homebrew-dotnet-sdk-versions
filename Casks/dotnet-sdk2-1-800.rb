cask "dotnet-sdk2-1-800" do
  version "2.1.811,2.1.23"
  sha256 "51d9f3ebe87e3fd63847d575e3adc20f4533ca51ab5dd0c43ba561f41c7d38d3"

  url "https://download.visualstudio.microsoft.com/download/pr/e431540d-fdb4-4504-afd9-e5ef64498ce9/5bac663ff1dc65e08dd9a5c63299e2dc/dotnet-sdk-2.1.811-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
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
