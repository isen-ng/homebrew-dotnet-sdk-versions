cask "dotnet-sdk3-1-300" do
  version "3.1.302,3.1.6"
  sha256 "c94d7ff32ada2a5df97fd34820b022986edc3d0d9db4a6d4a63f26be7adf4090"

  url "https://download.visualstudio.microsoft.com/download/pr/fff497aa-e6f6-4556-b67b-d139e772156f/4efa99b6bf0cb59104920dfd5f65f8a8/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :high_sierra"

  pkg "dotnet-sdk-#{version.csv.first}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.x64"

  zap pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ],
      trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
