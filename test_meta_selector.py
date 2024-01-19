import unittest
from meta_selector import MetaSelector
import tempfile
import os
import shutil


class MetaSelectorTests(unittest.TestCase):
    _workdir = None

    @classmethod
    def setUpClass(cls):
        cls._workdir = tempfile.mkdtemp()

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls._workdir)

    def test_run_should_select_highest_version_for_single_sdk_two_files(self):
        self.assertFalse(self._workdir is None)
        self.create_caskfile("7-0-200")
        expected_version = "7-0-400"
        self.create_caskfile(expected_version)
        expected_file = "dotnet-sdk7.rb"
        sut = self.create()

        sut.run()

        self.assertWorkFileExists(expected_file)
        # TODO: assert that the correct version has been selected in
        #       the generated file

    def create(self):
        return MetaSelector(self._workdir)

    def assertWorkFileExists(self, path: str):
        full_path = os.path.join(self._workdir, path)
        if os.path.exists(full_path):
            return
        self.fail(
            "expected to find file\n{}\nin\n{}".format(path, self._workdir)
        )

    def create_caskfile(self, version: str):
        filename = "dotnet-sdk{}.rb".format(version)
        with open(os.path.join(self._workdir, filename), mode="w") as fp:
            fp.write(
                self._definitions[version]
            )

    _definitions = {
        "6-0-100": """
cask "dotnet-sdk6-0-100" do
  arch arm: "arm64", intel: "x64"

  version "6.0.108,6.0.8"

  sha256_x64 = "c617e8972513c290b3ffccc6063d24d8d1aaadf3cc16c7c369e23bac9f450570"
  sha256_arm64 = "d37d779518fb573284176ab55f2b9606f982cf12a4aa9c220bbf6d353ad025b9"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/528fff70-36c8-4103-87fb-3717512537ad/9a96634944cde13e55e367778246057e/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/56748cfd-0e22-44b3-a253-018d156b076d/4f669bc1d8355e18c25a2b7b97e57cf6/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :mojave"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
        """.strip(),


        "7-0-200": """
cask "dotnet-sdk7-0-200" do
  arch arm: "arm64", intel: "x64"

  version "7.0.203,7.0.5"

  sha256_x64 = "82e6bfd3301d1b718e136fdaa1dd23d6abb03adbca05fcbc268b0da7e0d65b46"
  sha256_arm64 = "c80e0eabfa3681fa1db33c149ccbbb7de9155702aa5baaa11ea63f998151f326"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/08b3b509-05e6-4df1-84e1-a76c8855d899/d9b9a2d8ef9788f345d97304ceb67b07/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/a5070179-d53b-4a84-98d6-37a9d3ef458b/f8bba83817d23e3b7726746c59de4e0c/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :mojave"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
        """.strip(),


        "7-0-400": """
cask "dotnet-sdk7-0-200" do
  arch arm: "arm64", intel: "x64"

  version "7.0.203,7.0.5"

  sha256_x64 = "82e6bfd3301d1b718e136fdaa1dd23d6abb03adbca05fcbc268b0da7e0d65b46"
  sha256_arm64 = "c80e0eabfa3681fa1db33c149ccbbb7de9155702aa5baaa11ea63f998151f326"
  url_x64 = "https://download.visualstudio.microsoft.com/download/pr/08b3b509-05e6-4df1-84e1-a76c8855d899/d9b9a2d8ef9788f345d97304ceb67b07/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"
  url_arm64 = "https://download.visualstudio.microsoft.com/download/pr/a5070179-d53b-4a84-98d6-37a9d3ef458b/f8bba83817d23e3b7726746c59de4e0c/dotnet-sdk-#{version.csv.first}-osx-arm64.pkg"

  on_arm do
    sha256 sha256_arm64

    url url_arm64
  end
  on_intel do
    sha256 sha256_x64

    url url_x64
  end

  name ".NET Core SDK #{version.csv.first}"
  desc "This cask follows releases from https://github.com/dotnet/core/tree/master"
  homepage "https://www.microsoft.com/net/core#macos"

  livecheck do
    skip "See https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/CONTRIBUTING.md#automatic-updates"
  end

  depends_on macos: ">= :mojave"

  pkg "dotnet-sdk-#{version.csv.first}-osx-#{arch}.pkg"

  uninstall pkgutil: "com.microsoft.dotnet.dev.#{version.csv.first}.component.osx.#{arch}"

  zap trash:   ["~/.dotnet", "~/.nuget", "/etc/paths.d/dotnet", "/etc/paths.d/dotnet-cli-tools"],
      pkgutil: [
        "com.microsoft.dotnet.hostfxr.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedframework.Microsoft.NETCore.App.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.pack.apphost.#{version.csv.second}.component.osx.#{arch}",
        "com.microsoft.dotnet.sharedhost.component.osx.#{arch}",
      ]

  caveats "Uninstalling the offical dotnet-sdk casks will remove the shared runtime dependencies, " \
          "so you'll need to reinstall the particular version cask you want from this tap again " \
          "for the `dotnet` command to work again."
end
        """.strip()
    }