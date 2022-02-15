cask "dotnet-sdk5-0-400" do
  version "5.0.405,5.0.14"
  sha256 "96f2f1f658a413e53088d8ed4d47e9090073d15b0682519802b954437d5026b3"

  url "https://download.visualstudio.microsoft.com/download/pr/77ad3bf2-2229-44a0-a5d2-56d476bc9b90/a6356813f1e5934c1dff6f0391c5b826/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.csv.first}-osx-x64.pkg"

  postflight do
    FileUtils.ln_sf("/usr/local/share/dotnet/x64/dotnet", "#{HOMEBREW_PREFIX}/bin/dotnetx64") \
    unless Hardware::CPU.intel?
  end

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.x64"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "If you are installing this x64 binary on an Apple M1 (arm64) machine, the x64 version of `dotnet`"\
          "command will be symlinked as `dotnetx64`\n\n"\
          "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
