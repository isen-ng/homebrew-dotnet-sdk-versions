cask 'dotnet-sdk-2.1.500' do
  version '2.1.510,2.1.14'
  sha256 'e6ca8306070b561d2d3525ee449617f6ca5d22594b73c74fdc83df9dc4f98245'

  url 'https://download.visualstudio.microsoft.com/download/pr/a2c3ab2c-93dd-474d-9fb8-879afa46f4f4/0df8ed04c1164ebf7e27cbbea71a2444/dotnet-sdk-2.1.510-osx-x64.pkg'
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
