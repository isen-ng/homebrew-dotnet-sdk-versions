cask 'dotnet-sdk-2.2.100' do
  version '2.2.109,2.2.7'
  sha256 '6ba7279ba5faa0a12ade3e5e4fbb94c33c6ec80741cbdf53a661bc3f3ac2b2af'

  url 'https://download.visualstudio.microsoft.com/download/pr/0c022dcc-570d-4492-b356-a9f6f767e70c/aa2dc6b52682ec96528745fc591403b1/dotnet-sdk-2.2.109-osx-x64.pkg'
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
