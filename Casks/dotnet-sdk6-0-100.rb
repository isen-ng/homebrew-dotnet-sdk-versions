cask "dotnet-sdk6-0-100" do
  version "6.0.100,6.0.0"

  arch = Hardware::CPU.intel? ? "x64" : "arm64"
  link = Hardware::CPU.intel? ? "/usr/local/share/dotnet/x64/dotnet" : "/usr/local/share/dotnet/dotnet"
  sha256_x64 = "9203560506408d8f88774358b03cdcfcfa0495682fde6034b24f7ccaeddce2ef"
  sha256_arm64 = "df96e334b5ac10e9e4abccf81376f52da1ed0fb0ad3822709e3c27b8c0bfa01a"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/14a45451-4cc9-48e1-af69-0aff75891d09/ff6e83986a2a9a535015fb3104a90a1b/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/ed60d37e-7842-4fc2-8250-2bd66073d79e/725d486e04d27e45d2b41c687dc35f49/dotnet-sdk-#{version.before_comma}-osx-arm64.pkg"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  name ".NET Core SDK #{version.before_comma}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions"
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-#{arch}.pkg"

  postflight do
    FileUtils.ln_sf(link.to_s, "#{HOMEBREW_PREFIX}/bin/dotnet")
  end

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.after_comma}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you\'ll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
