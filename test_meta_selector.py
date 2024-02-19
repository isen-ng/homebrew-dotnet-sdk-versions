import unittest
from meta_selector import MetaSelector
import tempfile
import os
import shutil
import subprocess
from typing import List, Dict


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
        # file name already matched - the cask definition should too
        full_path = self.work_file(expected_file)
        with open(full_path, "r") as fp:
            lines = fp.readlines()
            interesting = [l for l in lines if l.startswith("cask")]
            self.assertEqual(1, len(interesting))
            self.assertEqual("cask \"dotnet-sdk7\" do", interesting[0].rstrip())

    def test_run_should_set_url_to_meta_readme_from_current_repository(self):
        # TODO: determine the location via `git remote -v`, observing the origin
        #       then test that this is what the script uses as the base url to META.md
        stdout = (subprocess.run(
            ["git", "remote", "-v"],
            stdout=subprocess.PIPE
        ).stdout.decode("utf-8")).splitlines()
        interesting = [l for l in stdout if l.startswith("origin")]
        first = interesting[0]
        if first.find("fluffynuts") > -1:
            expectedUrl = "https://raw.githubusercontent.com/fluffynuts/homebrew-dotnet-sdk-versions/master/META.md"
        else:
            # try to make this work when it's finally merged...
            expectedUrl = "https://raw.githubusercontent.com/isen-ng/homebrew-dotnet-sdk-versions/master/META.md"

        self.create_caskfile("7-0-200")
        expected_version = "7-0-400"
        self.create_caskfile(expected_version)
        expected_file = "dotnet-sdk7.rb"
        sut = self.create()

        sut.run()

        lines = self.read_work_file(expected_file)
        interesting = [l.strip() for l in lines if l.strip().startswith("url")]
        self.assertEqual(1, len(interesting))
        self.assertEqual(f"url \"{expectedUrl}\"", interesting[0])

    def test_run_should_add_dotnet_dependency(self):
        self.create_caskfile("7-0-200")
        expected_version = "7-0-400"
        self.create_caskfile(expected_version)
        expected_file = "dotnet-sdk7.rb"
        sut = self.create()

        sut.run()

        lines = self.read_work_file(expected_file)
        interesting = [l.strip() for l in lines if
                       l.strip().startswith("depends_on") and
                       l.find("cask") > -1]
        self.assertEqual(1, len(interesting))
        self.assertEqual(
            "depends_on cask: \"dotnet-sdk7-0-400\"",
            interesting[0]
        )

    def test_run_should_append_non_variable_lines(self):
        self.create_caskfile("7-0-200")
        expected_version = "7-0-400"
        self.create_caskfile(expected_version)
        expected_file = "dotnet-sdk7.rb"
        sut = self.create()

        sut.run()

        raw = self.read_work_file_raw(expected_file)
        self.assertContains(raw, "name \".NET Core SDK #{version.csv.first}\"")
        self.assertContains(raw, "desc \"This cask follows releases from https://github.com/dotnet/core/tree/master\"")
        self.assertContains(raw, "homepage \"https://www.microsoft.com/net/core#macos\"")

    def test_run_should_not_duplicate_depends_on(self):
        self.create_caskfile("7-0-200")
        expected_version = "7-0-400"
        self.create_caskfile(expected_version)
        expected_file = "dotnet-sdk7.rb"
        sut = self.create()

        sut.run()

        lines = self.read_work_file(expected_file)
        depends_on_lines = [ l for l in lines if l.find("depends_on") > -1 ]
        macos_depends = [ l for l in depends_on_lines if l.find("macos") > -1]
        self.assertEqual(1, len(macos_depends))

    def test_parse_origin_remote_ssh(self):
        sut = self.create()
        url = "ssh://git@github.com/owner/repo"

        result = sut.parse_origin_remote(url)

        self.assertEqual(result[0], "owner")
        self.assertEqual(result[1], "repo")

    def assertContains(self, actual, expected):
        self.assertTrue(actual.find(expected) > -1)

    def create(self):
        sut = MetaSelector(self._workdir)
        sut.quiet = True
        return sut

    def work_file(self, relative_path: str):
        return os.path.join(self._workdir, relative_path);

    def read_work_file(self, relative_path: str) -> List[str]:
        self.assertWorkFileExists(relative_path)
        full_path = self.work_file(relative_path)
        with open(full_path, "r") as fp:
            return fp.readlines()

    def read_work_file_raw(self, relative_path: str) -> str:
        self.assertWorkFileExists(relative_path)
        full_path = self.work_file(relative_path)
        with open(full_path, "r") as fp:
            return fp.read()

    def assertWorkFileExists(self, name: str):
        full_path = self.work_file(name)
        if os.path.exists(full_path):
            return
        self.fail(
            "expected to find file\n{}\nin\n{}".format(name, self._workdir)
        )

    def create_caskfile(self, version: str):
        filename = "dotnet-sdk{}.rb".format(version)
        with open(os.path.join(self._workdir, filename), mode="w") as fp:
            fp.write(
                self._definitions[version]
            )

    # the final files should look something like this, which
    # was hand-crafted very similarly on a mac and worked there
    # to install the README.md from the repo (because META.md isn't
    # there yet - that's also going to be fun to fix) and the
    # mentioned dotnet sdk dependency
    __example__ = """
cask "dotnet-sdk7" do                   # name should be generated by the meta_selector tool
    arch arm: "arm64", intel: "x64"     # *
    version "7.0.405,7.0.15"            # *
    
    # TODO: this must still be added by meta_selector
    url "https://github.com/isen-ng/homebrew-dotnet-sdk-versions/blob/master/META.md"
    
    name ".NET Core SDK #{version.csv.first}" # *
    desc "This cask follows releases from https://github.com/dotnet/core/tree/master" # *
    homepage: "https://www.microsoft.com/net/core#macos" # *
    
    depends_on macos: ">= :mojave"      # *
    
    # TODO: this must still be added by meta_selector
    depends_on cask: "dotnet-sdk7-0-400"
    
    caveats "" # * (and I have to figure out multi-line for this too)
end
    """

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
