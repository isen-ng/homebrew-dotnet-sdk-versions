cask 'dotnet-sdk-2.1.500' do
  version '2.1.514,2.1.18'
  sha256 '755b4542c8e9dee1c4f2eeb026e5ac4de59103acd714b4363d21ba20be09ea2d'

  url 'https://download.visualstudio.microsoft.com/download/pr/1a79bb3d-7d99-4a50-88d3-31901564f05e/0f4a860125fa9e1ad447dcd603c5fc5b/dotnet-sdk-2.1.514-osx-x64.pkg'
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
