cask "dotnet-sdk8-0-200" do
  arch arm: "arm64", intel: "x64"

  version "8.0.202,8.0.3"

  sha256_x64 = "24f120baad91d7b445507f9d30b5e69471ee45b95bbf297eda147217bc873542"
  sha256_arm64 = "5295e7735886e44cc9977b9f22aa4bc044fd03220931016c5267a5de44e70636"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/15530a86-8714-4828-a934-8058c3673e1a/738ed9cd4f6eaf7367c9bda26999652e/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/4f1f4135-d42a-4ede-9838-85672f82f08c/fffd37265287676bb7b745f4531d8607/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :catalina"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ],
      trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
