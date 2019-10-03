cask 'dotnet-sdk-2.1.500' do
  version '2.1.509,2.1.13'
  sha256 'eb98bcc2c2746eb9e43de8d4d4b302a83b1cde826488840f7f82f5595c220cfe'

  url 'https://download.visualstudio.microsoft.com/download/pr/b03b2d53-5c82-471a-b263-71e59db10737/683146f10e503f20ab630a7fd950b7ee/dotnet-sdk-2.1.509-osx-x64.pkg'
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
