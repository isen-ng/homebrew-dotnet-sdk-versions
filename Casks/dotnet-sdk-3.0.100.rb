cask 'dotnet-sdk-3.0.100' do
  version '3.0.101,3.0.1'
  sha256 '9d40f99047c2713efcf48c67c80b3bac0fcd24c87bdf7263b8e37e3bdf9901e9'

  url 'https://download.visualstudio.microsoft.com/download/pr/1b9f265d-ba27-4f0c-8b4d-1fd42bd8448b/2bbd64abddeeea91149df3aa39d049ae/dotnet-sdk-3.0.101-osx-x64.pkg'
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
