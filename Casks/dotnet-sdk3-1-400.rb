cask "dotnet-sdk3-1-400" do
  version "3.1.425,3.1.31"
  sha256 "0f1e33650d2016e6f1e70228b7cc7685a68ae19819996837463816ffcdaa8936"

  url "https://download.visualstudio.microsoft.com/download/pr/861832ec-7a22-401f-ab1c-1bed35a50bbc/77067aa8919546dbf9ebef6b34137770/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
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
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
