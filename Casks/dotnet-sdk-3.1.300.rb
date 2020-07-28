cask "dotnet-sdk-3.1.300" do
  version "3.1.302,3.1.6"
  sha256 "c94d7ff32ada2a5df97fd34820b022986edc3d0d9db4a6d4a63f26be7adf4090"

  url "https://download.visualstudio.microsoft.com/download/pr/fff497aa-e6f6-4556-b67b-d139e772156f/4efa99b6bf0cb59104920dfd5f65f8a8/dotnet-sdk-3.1.302-osx-x64.pkg"
  name ".NET Core SDK #{version.before_comma}"
  homepage "https://www.microsoft.com/net/core#macos"

  if MacOS.version > :sierra
    conflicts_with cask: [
      "dotnet",
      "dotnet-sdk",
    ]
  end

  depends_on macos: "> :sierra"

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  binary "/usr/local/share/dotnet/dotnet"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
            delete:  [
              "/etc/paths.d/dotnet",
              "/etc/paths.d/dotnet-cli-tools",
            ]

  zap trash:   ["~/.dotnet", "~/.nuget"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
        "com.microsoft.dotnet.sharedhost.component.osx.x64",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, "\
          "so you'll need to reinstall the particular version cask you want from this tap again "\
          "for the `dotnet` command to work again."
end
