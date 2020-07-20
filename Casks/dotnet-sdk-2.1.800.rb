cask 'dotnet-sdk-2.1.800' do
  version '2.1.808,2.1.20'
  sha256 'fe43f9d39a02c6b480bb370dbbd0dbb0a6271a3c0ca497767d0b5cef07a1fce4'

  url 'https://download.visualstudio.microsoft.com/download/pr/6190a306-fbbb-4dcc-82a7-a9e78558602c/884abdcb3990ed4e45659032abc54fab/dotnet-sdk-2.1.808-osx-x64.pkg'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  depends_on macos: '>= :sierra'

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

  zap trash:   [
                 '~/.dotnet',
                 '~/.nuget',
               ],
      pkgutil: [
                 "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
                 "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
                 'com.microsoft.dotnet.sharedhost.component.osx.x64',
               ]

  caveats 'Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, '\
          'so you\'ll need to reinstall the particular version cask you want from this tap again '\
          'for the `dotnet` command to work again.'
end
