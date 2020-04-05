cask 'dotnet-sdk-3.1.100' do
  version '3.1.103,3.1.3'
  sha256 '0b075553dd73fd15eeb26c6baeecf8431e441d24fb4cc403fb03339705d9fd9b'

  url 'https://download.visualstudio.microsoft.com/download/pr/d200c4ea-dc59-43d7-80f4-04d277c3c60b/ecf4c1b9c84f1ee887afbdf02ea60c3f/dotnet-sdk-3.1.103-osx-x64.pkg'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  depends_on macos: '> :sierra'

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
