cask "dotnet-sdk6-0-400" do
  arch arm: "arm64", intel: "x64"

  version "6.0.405,6.0.13"

  sha256_x64 = "d3bebc30a42235b8999e010b3229f47fa558451d7892581bf94af40995559cbf"
  sha256_arm64 = "ee67a3b43769b4c23394c996b2e28dab4c74dc6af3150041416fd28de4c9a933"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/8a0c7611-7ca1-49d7-a889-e6514fc29dd0/08927286063140ccdf88eafe0e3bd2fb/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/ee832565-1555-453e-8efc-5ea49e2e68d1/57de20cb37dedd138921ec4ea6c6c882/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

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
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
