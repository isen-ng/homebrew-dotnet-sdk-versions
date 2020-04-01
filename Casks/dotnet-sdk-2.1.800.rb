cask 'dotnet-sdk-2.1.800' do
  version '2.1.805,2.1.17'
  sha256 '3f9d2960f92665b68b79967b1092f638dcdca05f79a2e3cde659fa0566c931ed'

  url 'https://download.visualstudio.microsoft.com/download/pr/1f42da0e-a749-4338-ac39-5160a1f31ab0/74f8b6c934b0dc3024f336460c89e8ad/dotnet-sdk-2.1.805-osx-x64.pkg'
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
