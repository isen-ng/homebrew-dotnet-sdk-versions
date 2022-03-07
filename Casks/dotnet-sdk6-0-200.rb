cask "dotnet-sdk6-0-200" do
  version "6.0.200,6.0.2"

  arch = Hardware::CPU.intel? ? "x64" : "arm64"
  sha256_x64 = "10e3df96b7dcb750dab7a07dee1c3db4cf7bf15deefd983abda372370d3c6356"
  sha256_arm64 = "4211585bcb8cd9c7ad2e2a0d5388f26d2585ca9139e87d142bc2ba535c600986"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/0f1f23eb-004f-41a2-a4ef-e1a9b533a794/f2d47f0ed6a7be2027166ea1132cc806/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/ba037891-7f55-4f23-9997-92c1b642117b/a643faacd4700bb4565eb83fb11b3293/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
