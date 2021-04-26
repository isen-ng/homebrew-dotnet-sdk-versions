cask "dotnet-sdk2-1-500" do
  version "2.1.523,2.1.27"
  sha256 "288519b6fc87f245c4e53212b4629f7e887b7d49617a1899b202760e7caf092b"

  url "https://download.visualstudio.microsoft.com/download/pr/86a6d223-85fb-4d80-98bb-e45cab9926db/66bbeeb674f783e70b2b5b672d2a4972/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  appcast "https://github.com/dotnet/sdk/releases.atom"
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
