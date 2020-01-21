cask 'dotnet-sdk-3.1.100' do
  version '3.1.101,3.1.1'
  sha256 '89c9a9bbc50c15d3873b87e9c030b85a2021a8c4e881c8b86d718164970f7d2b'

  url 'https://download.visualstudio.microsoft.com/download/pr/749db4bc-73c3-4ffb-a545-c315dc9a0ca8/5281258f5dcae636efe557b8b305e20b/dotnet-sdk-3.1.101-osx-x64.pkg'
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
