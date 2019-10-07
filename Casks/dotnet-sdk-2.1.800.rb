cask 'dotnet-sdk-2.1.800' do
  version '2.1.802,2.1.13'
  sha256 'a2d4b58d3893af102a505fd0522a2f7138bf09783ca1a3dab870fc1cc12bfdc1'

  url 'https://download.visualstudio.microsoft.com/download/pr/3998e58a-46dd-4f9c-a0e2-d17309de20fb/d694ddf3d8f99e8dee928e0b46f15084/dotnet-sdk-2.1.802-osx-x64.pkg'
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
