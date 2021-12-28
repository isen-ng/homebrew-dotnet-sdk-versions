#!/usr/bin/env python

import argparse
import glob
import hashlib
import json
import os
import re
import requests
import urllib.request


class SdkVersion:
    def __init__(self, version_string):
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        self.feature = int(version_split[2][0])
        self.patch = int(version_split[2][-2:])
        self.version_string = version_string

    def __str__(self):
        return self.version_string

    def getMajor(self):
        return '{0}'.format(self.major)

    def getMajorMinor(self):
        return '{0}.{1}'.format(self.major, self.minor)

    def getMajorMinorFeature(self):
        return '{0}.{1}.{2}'.format(self.major, self.minor, self.feature)

    def getMajorMinorFeaturePath(self):
        return self.version_string

    def __eq__(self, other):
        return self.version_string == other.version_string

    def __ne__(self, other):
        return not self.version_string == other.version_string

    def __gt__(self, other):
        return other < self

    def __ge__(self, other):
        return not self < other

    def __le__(self, other):
        return not other < self

    def __lt__(self, other):
        return self.major < other.major \
            or self.minor < other.minor \
            or self.feature < other.feature \
            or self.patch < other.patch


class RuntimeVersion:
    def __init__(self, version_string):
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        self.patch = int(version_split[2])
        self.version_string = version_string

    def __str__(self):
        return self.version_string

    def getMajor(self):
        return '{0}'.format(self.major)

    def getMajorMinor(self):
        return '{0}.{1}'.format(self.major, self.minor)

    def getMajorMinorPatch(self):
        return self.version_string

    def __eq__(self, other):
        return self.version_string == other.version_string

    def __ne__(self, other):
        return not self.version_string == other.version_string

    def __gt__(self, other):
        return other < self

    def __ge__(self, other):
        return not self < other

    def __le__(self, other):
        return not other < self

    def __lt__(self, other):
        return self.major < other.major \
            or self.minor < other.minor \
            or self.patch < other.patch


class Application:
    # `version "6.0.100,6.0.0"`
    version_pattern = re.compile('version "([0-9.,]+)"')

    # `sha256 "d290cefddb4fbdf1215724c049d86b4ce09f5dc2c5a658e3c1645c368f34c31a"`
    sha_256_pattern = re.compile('sha256 "([0-9a-z]+)"')

    # `url "https://download.visualstudio.microsoft.com/download/pr/38102737-cb48-46c2-8f52-fb7102b50ae7/d81958d71c3c2679796e1ecfbd9cc903/dotnet-sdk-#{version.before_comma}-osx-x64.pkg"`
    url_pattern = re.compile('url "([^\s]+)"')

    sha_256_x64_pattern = re.compile('sha256_x64 = "([0-9a-z]+)"')
    sha_256_arm64_pattern = re.compile('sha256_arm64 = "([0-9a-z]+)"')
    url_x64_pattern = re.compile('url_x64 = "([^\s]+)"')
    url_arm64_pattern = re.compile('url_arm64 = "([^\s]+)"')

    really_push = False

    @staticmethod
    def run():
        for file_path in glob.glob('Casks/*.rb'):
            Application._output("------------------------------------")
            Application._output("{0}: Checking for updates  ...".format(file_path))

            (sdk_version, runtime_version) = Application._find_versions(file_path)
            Application._log('sdk_version', sdk_version)
            Application._log('runtime_version', runtime_version)

            is_arm_supported = Application._cask_supports_arm(file_path)
            Application._log('is_arm_supported', is_arm_supported)

            releases_json = Application._download_release_json(sdk_version)
            (latest_sdk_release, latest_sdk_release_version) = Application._find_latest_sdk_release(sdk_version, releases_json)

            if latest_sdk_release is None:
                Application._output("No latest version found for {0}. Skipping.".format(file_path))
                continue

            if latest_sdk_release_version <= sdk_version:
                Application._output("Latest version[{0}] is not greater than current version[{1}]. Skipping".format(latest_sdk_release_version, sdk_version))
                continue

            git_branch_name = Application._prepare_git_branch(file_path, latest_sdk_release)

            is_cask_updated = False
            if is_arm_supported:
                is_cask_updated = Application._update_intel_arm_cask(file_path, latest_sdk_release)
            else:
                is_cask_updated = Application._update_intel_only_cask(file_path, latest_sdk_release)  

            if is_cask_updated:
                Application._update_read_me(sdk_version, latest_sdk_release)
                Application._push_git_branch(file_path, sdk_version, latest_sdk_release, git_branch_name)

    @staticmethod
    def _find_versions(file_path):
        with open(file_path, 'r') as file:
            for line in file:
                match = Application.version_pattern.search(line.strip())
                if not match:
                    continue

                # split `6.0.100,6.0.0` on comma
                version_split = match.group(1).split(',')

                return SdkVersion(version_split[0]), RuntimeVersion(version_split[1])

            raise Exception('Cannot find version in cask: {0}'.format(file_path))

    @staticmethod
    def _download_release_json(sdk_version):
        sdk_major_minor_version = sdk_version.getMajorMinor()

        url = 'https://raw.githubusercontent.com/dotnet/core/master/release-notes/{}/releases.json'.format(sdk_major_minor_version)
        with urllib.request.urlopen(url) as f:
            return json.loads(f.read().decode('utf-8'))

    @staticmethod
    def _find_latest_sdk_release(sdk_version, releases_json):
        sdk_major_minor_feature_version = sdk_version.getMajorMinorFeature()
        sdk_major_minor_feature_version_regex = '^' + sdk_major_minor_feature_version + '[0-9]{2}$'

        latest_sdk_release = None
        latest_sdk_release_version = None
        releases = releases_json['releases']

        for release in releases:
            match = re.search(sdk_major_minor_feature_version_regex, release['sdk']['version'])
            if not match:
                continue

            if latest_sdk_release == None:
                latest_sdk_release = release
                latest_sdk_release_version = SdkVersion(release['sdk']['version'])
            else:
                release_version = SdkVersion(release['sdk']['version'])
                if release_version > latest_sdk_release_version:
                    latest_sdk_release = release
                    latest_sdk_release_version = release_version

        return latest_sdk_release, latest_sdk_release_version

    @staticmethod
    def _cask_supports_arm(file_path):
        with open(file_path, 'r') as file:
            for line in file:
                if 'arch = Hardware::CPU.intel? ? "x64" : "arm64"' in line.strip(): 
                    return True

            return False

    @staticmethod
    def _update_intel_only_cask(file_path, latest_sdk_release):
        sdk_url, sha_256 = Application._find_download_and_verify_sdk_url(latest_sdk_release, 'x64')
        if sdk_url is None:
            return False

        with open(file_path, 'r') as file:
            content = file.read()

        # url needs to have SOME version interpolation to make brew audit happy
        url_with_interpolation = sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.before_comma}')

        new_version = 'version "{0},{1}"'.format(latest_sdk_release['sdk']['version'], latest_sdk_release['runtime']['version'])
        new_sha_256 = 'sha256 "{0}"'.format(sha_256)
        new_url = 'url "{0}"'.format(url_with_interpolation)
        Application._log('new_version', new_version)
        Application._log('new_sha_256', new_sha_256)
        Application._log('new_url', new_url)

        content = Application.version_pattern.sub(new_version, content)
        content = Application.sha_256_pattern.sub(new_sha_256, content)
        content = Application.url_pattern.sub(new_url, content)

        with open(file_path, 'w') as file:
            file.write(content)

        return True

    @staticmethod
    def _update_intel_arm_cask(file_path, latest_sdk_release):
        x64_sdk_url, x64_sha_256 = Application._find_download_and_verify_sdk_url(latest_sdk_release, 'x64')
        arm64_sdk_url, arm64_sha_256 = Application._find_download_and_verify_sdk_url(latest_sdk_release, 'arm64')
        if x64_sdk_url is None or arm64_sdk_url is None:
            return False

        with open(file_path, 'r') as file:
            content = file.read()

        # url needs to have SOME version interpolation to make brew audit happy
        x64_url_with_interpolation = x64_sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.before_comma}')
        arm64_url_with_interpolation = arm64_sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.before_comma}')

        new_version = 'version "{0},{1}"'.format(latest_sdk_release['sdk']['version'], latest_sdk_release['runtime']['version'])
        new_x64_sha_256 = 'sha256_x64 "{0}"'.format(x64_sha_256)
        new_x64_url = 'url_x64 "{0}"'.format(x64_url_with_interpolation)
        new_arm64_sha_256 = 'sha256_arm64 "{0}"'.format(arm64_sha_256)
        new_arm64_url = 'url_arm64 "{0}"'.format(arm64_url_with_interpolation)
        Application._log('new_version', new_version)
        Application._log('new_x64_sha_256', new_x64_sha_256)
        Application._log('new_x64_url', new_x64_url)
        Application._log('new_arm64_sha_256', new_arm64_sha_256)
        Application._log('new_arm64_url', new_arm64_url)

        content = Application.version_pattern.sub(new_version, content)
        content = Application.sha_256_x64_pattern.sub(new_x64_sha_256, content)
        content = Application.url_x64_pattern.sub(new_x64_url, content)
        content = Application.sha_256_arm64_pattern.sub(new_arm64_sha_256, content)
        content = Application.url_arm64_pattern.sub(new_arm64_url, content)

        with open(file_path, 'w') as file:
            file.write(content)

        return True

    @staticmethod    
    def _update_read_me(sdk_release, latest_sdk_release):
        file_path = 'README.md'

        with open(file_path, 'r') as file:
            content = file.read()

        content = content.replace(str(sdk_release), latest_sdk_release['sdk']['version'])

        with open(file_path, 'w') as file:
            file.write(content)

    @staticmethod
    def _find_download_and_verify_sdk_url(sdk_release, arch):
        sdk_url, sdk_sha_512 = Application._find_sdk_url(sdk_release, arch)
        if sdk_url is None:
            Application._output("Could not find sdk url for sdk_release[{0}]. Skipping".format(sdk_release['sdk']['version']))
            return None, None

        sha_256, sha_512 = Application._download_and_calculate_sha256(sdk_url)
        if not sdk_sha_512 == sha_512:
            Application._output("Downloaded sha512[{0}] does not match provided sha512[{1}]. Man-in-the-middle? Skipping".format(sha_512, sdk_sha_512))
            return None, None

        return sdk_url, sha_256

    @staticmethod
    def _find_sdk_url(sdk_release, arch):
        name = 'dotnet-sdk-osx-{}.pkg'.format(arch)
        for file in sdk_release['sdk']['files']:
            if file['name'] == name:
                return file['url'], file['hash']

        return None

    @staticmethod
    def _download_and_calculate_sha256(url):
        sha256 = hashlib.sha256()
        sha512 = hashlib.sha512()

        with requests.get(url, stream = True) as r:
            r.raise_for_status()
            for chunk in r.iter_content(chunk_size=8192): 
                if chunk:
                    sha256.update(chunk)
                    sha512.update(chunk)


        return sha256.hexdigest(), sha512.hexdigest()

    @staticmethod
    def _prepare_git_branch(file_path, latest_sdk_release):
        branch_name = "update-{0}-to-{1}".format(file_path, latest_sdk_release['sdk']['version'])

        if Application.really_push:
            os.system('git checkout -b "{0}" || git checkout "{0}"'.format(branch_name))
            os.system('git reset --hard origin/master')

        return branch_name

    @staticmethod
    def _push_git_branch(file_path, sdk_version, latest_sdk_release, branch_name):
        commit_message = '[Auto] update {0} from {1} to {2}'.format(file_path, str(sdk_version), latest_sdk_release['sdk']['version'])

        if Application.really_push:
            os.system('git add {0}'.format(file_path))
            os.system('git add {0}'.format('README.md'))
            os.system('git commit -m "{0}"'.format(commit_message))
            os.system('git push origin --force {0}'.format(branch_name))
            os.system('hub pull-request --base master --head "{0}" -m "{1}"'.format(branch_name, commit_message))

    @staticmethod
    def _log(name, value = ''):
        print('{0}: {1}'.format(name, str(value)))

    @staticmethod
    def _output(message):
        print(message)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--really_push", action='store_true', default=False, help='Indicates whether we really push to git or not')

    args = parser.parse_args()
    Application.really_push = args.really_push

    Application.run()
