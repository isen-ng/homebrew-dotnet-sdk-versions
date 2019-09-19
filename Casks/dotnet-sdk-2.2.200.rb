cask 'dotnet-sdk-2.2.200' do
  version '2.2.206,2.2.7'
  sha256 '79648a5342a15927450b37c5ea3b79f3c5966bba369d438f50d0d52de8d44440'

  url 'https://download.visualstudio.microsoft.com/download/pr/99c2d142-7782-4c78-9052-0d35d441af23/aadba3d0ee3ba5b407648d446580891b/dotnet-sdk-2.2.206-osx-x64.pkg'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  depends_on macos: '>= :sierra'

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

  zap trash:  [
                '~/.dotnet',
                '~/.nuget',
              ],
      pkgutil:
              [
                "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
                "com.microsoft.dotnet.hostfxr.#{version.after_comma}.component.osx.x64",
                "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.after_comma}.component.osx.x64",
                'com.microsoft.dotnet.sharedhost.component.osx.x64',
              ]
end
