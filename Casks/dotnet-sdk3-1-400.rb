cask "dotnet-sdk3-1-400" do
  version "3.1.424,3.1.30"
  sha256 "ae9587a21bdb77ab4d704ef250526c9cb0e6bab78deb0996f1a324e23692c0b2"

  url "https://download.visualstudio.microsoft.com/download/pr/0196b062-8cbf-448b-a3ea-feee21c2b4da/7b15b845099274b2f046af149e594f00/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :high_sierra"

  pkg "dotnet-sdk-#{version.csv.first}-osx-x64.pkg"

  on_arm do
    FileUtils.ln_sf("/usr/local/share/dotnet/x64/dotnet", "#{HOMEBREW_PREFIX}/bin/dotnetx64") \
  end

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.x64"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "If you are installing this x64 binary on an Apple M1 (arm64) machine, the x64 version of `dotnet`" \
          "command will be symlinked as `dotnetx64`\n\n" \
          "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you\'ll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
