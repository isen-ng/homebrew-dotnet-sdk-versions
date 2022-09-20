cask "dotnet-sdk6-0-400" do
  arch arm: "arm64", intel: "x64"

  version "6.0.401,6.0.9"

  sha256_x64 = "667920bf202c420d57091f24b8051bad8ed174e131c4c15f45f79b2a785c3744"
  sha256_arm64 = "74898e91854bf89fd06a47efabc7fbc275ac2e80d7ed44beb6d6d20db39017ac"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/c98d3ccf-561c-4f9b-a1d7-5debb0880031/fd1ebfbd783788649ee139c229cd48fa/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/1011a115-ca23-4bad-8632-f9a96e47d0f0/164a08cde051b61a1669d2242770ef25/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_intel do
    sha256 sha256_x64
    url url_x64
  end
  on_arm do
    sha256 sha256_arm64
    url url_arm64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :mojave"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you\'ll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
