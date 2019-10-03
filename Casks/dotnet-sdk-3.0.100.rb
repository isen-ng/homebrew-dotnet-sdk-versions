cask 'dotnet-sdk-3.0.100' do
  version '3.0.100,3.0.0'
  sha256 '6a5a475d9aa1955470cd2370c9f501bc6a5a05ad5fb74109ddb9da278b55101a'

  url 'https://download.visualstudio.microsoft.com/download/pr/5c281f95-91c4-499d-baa2-31fec919047a/38c6964d72438ac30032bce516b655d9/dotnet-sdk-3.0.100-osx-x64.pkg'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  if MacOS.version > :sierra
    conflicts_with cask: [
                           'dotnet',
                           'dotnet-sdk',
                         ]
  end
  
  depends_on macos: '>= :sierra'

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  binary '/usr/local/share/dotnet/dotnet'

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
            delete:  [
                       '/etc/paths.d/dotnet',
                       '/etc/paths.d/dotnet-cli-tools',
                     ]

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
