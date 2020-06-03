cask 'dotnet-sdk-2.1.800' do
  version '2.1.806,2.1.18'
  sha256 'a52d5fc1c51726b5a349574dde4c4a9250f312a28907cfd6ac6384fa329cebc3'

  url 'https://download.visualstudio.microsoft.com/download/pr/7d18ea81-1124-4a08-bc8d-cc436f48e47e/d9b45de44d764cbfa23aa8a27b779c96/dotnet-sdk-2.1.806-osx-x64.pkg'
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
