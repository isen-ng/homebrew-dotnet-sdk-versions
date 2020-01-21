cask 'dotnet-sdk-2.1.800' do
  version '2.1.803,2.1.15'
  sha256 '912af1ba9ecc14345290c031f7d28a903006a4e7d1aefcd7406e02ec1a4727b9'

  url 'https://download.visualstudio.microsoft.com/download/pr/81c0b023-b5d7-4753-a9b6-2c7b374913f7/28b113347413fe5fff3976e7ce601724/dotnet-sdk-2.1.803-osx-x64.pkg'
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
