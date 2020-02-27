cask 'dotnet-sdk-3.1.100' do
  version '3.1.102,3.1.2'
  sha256 '15a9bf1cddd4be6f69895b031c53318573930f787c2babb4e174f2ed31656913'

  url 'https://download.visualstudio.microsoft.com/download/pr/3533d626-4784-4944-9d3a-e62b9b46d11a/770e2b9c1a40546a19e063c39996fe7d/dotnet-sdk-3.1.102-osx-x64.pkg'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  if MacOS.version > :sierra
    conflicts_with cask: [
                           'dotnet',
                           'dotnet-sdk',
                         ]
  end

  depends_on macos: '> :sierra'

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
