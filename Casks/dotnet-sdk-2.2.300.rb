cask 'dotnet-sdk-2.2.300' do
  version '2.2.300,60aefe1e-e5af-4a40-8985-7e4d270a53aa:5033e8abbd2e218abf77207611be0504'
  sha256 'f7ba19f3f30af6db1e9fb760ac9f9e7d1ce7acb1c204223a1c1bae02cbab493a'

  url "https://download.visualstudio.microsoft.com/download/pr/#{version.after_comma.before_colon}/#{version.after_colon}/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"
  appcast 'https://www.microsoft.com/net/download/macos'
  name ".NET Core SDK #{version.before_comma}"
  homepage 'https://www.microsoft.com/net/core#macos'

  depends_on macos: '>= :sierra'

  pkg "dotnet-sdk-#{version.before_comma}-osx-x64.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64"

  zap trash: [
    '~/.dotnet',
    '~/.nuget'
  ],
      pkgutil: [
        "com.microsoft.dotnet.dev.#{version.before_comma}.component.osx.x64",
        'com.microsoft.dotnet.hostfxr.2.2.5.component.osx.x64',
        'com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.2.2.5.component.osx.x64',
        'com.microsoft.dotnet.sharedhost.component.osx.x64'
      ]
end
