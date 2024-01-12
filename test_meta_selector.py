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

    def test_run_should_select_highest_version_for_single_sdk(self):
        self.assertFalse(self._workdir is None)
        self.create_caskfile("7-0-100")
        expected_version = "7-0-200"
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
        filename = "dotnet-sdk{}".format(version)
        with open(os.path.join(self._workdir, filename), mode="w") as fp:
            fp.write(
                """
                cask "{}" do
                end
                """.format(version).strip()
            )
