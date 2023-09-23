#!/usr/bin/env python

import argparse
import glob
import hashlib
import json
import re
import subprocess
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


class PreviewSdkVersion:
    def __init__(self, version_string):
        # 7.0.100-preview.1.22110.4, 8.0.100-rc.1.23463.5
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        self.feature = int(version_split[2][0])
        self.patch = int(version_split[2].split('-')[0][1:])
        self.is_rc = 'rc' in version_split[2]
        self.update = int(version_split[3])
        self.build = int(version_split[4])
        self.update_specific_build = int(version_split[5])
        self.version_string = version_string

    def __str__(self):
        return self.version_string

    def getMajorMinor(self):
        return '{0}.{1}'.format(self.major, self.minor)

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
        return (self.major < other.major \
            or self.minor < other.minor \
            or self.update < other.update) \
            and self.is_rc <= other.is_rc


class PreviewRuntimeVersion:
    def __init__(self, version_string):
        # 7.0.0-preview.7.22375.6
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        self.patch = int(version_split[2].split('-')[0])
        self.is_rc = 'rc' in version_split[2]
        self.update = int(version_split[3])
        self.build = int(version_split[4])
        self.update_specific_build = int(version_split[5])
        self.version_string = version_string

    def __str__(self):
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
        return (self.major < other.major \
            or self.minor < other.minor \
            or self.update < other.update) \
            and self.is_rc < other.is_rc


class CaskService:
    # `sha256 "d290cefddb4fbdf1215724c049d86b4ce09f5dc2c5a658e3c1645c368f34c31a"`
    sha_256_pattern = re.compile('sha256 "([0-9a-z]+)"')

    # `url "https://download.visualstudio.microsoft.com/download/pr/38102737-cb48-46c2-8f52-fb7102b50ae7/d81958d71c3c2679796e1ecfbd9cc903/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"`
    url_pattern = re.compile('url "([^\s]+)"')

    sha_256_x64_pattern = re.compile('sha256_x64 = "([0-9a-z]+)"')
    sha_256_arm64_pattern = re.compile('sha256_arm64 = "([0-9a-z]+)"')
    url_x64_pattern = re.compile('url_x64 = "([^\s]+)"')
    url_arm64_pattern = re.compile('url_arm64 = "([^\s]+)"')

    def __init__(self, version_pattern):
        self.version_pattern = version_pattern

    @staticmethod
    def cask_supports_arm(file_path):
        with open(file_path, 'r') as file:
            for line in file:
                if 'arch arm: "arm64", intel: "x64"' in line.strip(): 
                    return True

            return False

    @staticmethod
    def download_release_json(sdk_version):
        sdk_major_minor_version = sdk_version.getMajorMinor()

        url = 'https://raw.githubusercontent.com/dotnet/core/master/release-notes/{}/releases.json'.format(sdk_major_minor_version)
        with urllib.request.urlopen(url) as f:
            return json.loads(f.read().decode('utf-8'))

    def update_intel_only_cask(self, file_path, latest_sdk_release):
        sdk_url, sha_256 = self._find_download_and_verify_sdk_url(latest_sdk_release, 'x64')
        if sdk_url is None:
            return False

        with open(file_path, 'r') as file:
            content = file.read()

        # url needs to have SOME version interpolation to make brew audit happy
        url_with_interpolation = sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.csv.first}')

        new_version = 'version "{0},{1}"'.format(latest_sdk_release['sdk']['version'], latest_sdk_release['runtime']['version'])
        new_sha_256 = 'sha256 "{0}"'.format(sha_256)
        new_url = 'url "{0}"'.format(url_with_interpolation)
        Logger.log('new_version', new_version)
        Logger.log('new_sha_256', new_sha_256)
        Logger.log('new_url', new_url)

        content = self.version_pattern.sub(new_version, content)
        content = self.sha_256_pattern.sub(new_sha_256, content)
        content = self.url_pattern.sub(new_url, content)

        with open(file_path, 'w') as file:
            file.write(content)

        return True

    def update_intel_arm_cask(self, file_path, latest_sdk_release):
        x64_sdk_url, x64_sha_256 = self._find_download_and_verify_sdk_url(latest_sdk_release, 'x64')
        arm64_sdk_url, arm64_sha_256 = self._find_download_and_verify_sdk_url(latest_sdk_release, 'arm64')
        if x64_sdk_url is None or arm64_sdk_url is None:
            return False

        with open(file_path, 'r') as file:
            content = file.read()

        # url needs to have SOME version interpolation to make brew audit happy
        x64_url_with_interpolation = x64_sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.csv.first}')
        arm64_url_with_interpolation = arm64_sdk_url.replace(latest_sdk_release['sdk']['version'], '#{version.csv.first}')

        new_version = 'version "{0},{1}"'.format(latest_sdk_release['sdk']['version'], latest_sdk_release['runtime']['version'])
        new_x64_sha_256 = 'sha256_x64 = "{0}"'.format(x64_sha_256)
        new_x64_url = 'url_x64 = "{0}"'.format(x64_url_with_interpolation)
        new_arm64_sha_256 = 'sha256_arm64 = "{0}"'.format(arm64_sha_256)
        new_arm64_url = 'url_arm64 = "{0}"'.format(arm64_url_with_interpolation)
        Logger.log('new_version', new_version)
        Logger.log('new_x64_sha_256', new_x64_sha_256)
        Logger.log('new_x64_url', new_x64_url)
        Logger.log('new_arm64_sha_256', new_arm64_sha_256)
        Logger.log('new_arm64_url', new_arm64_url)

        content = self.version_pattern.sub(new_version, content)
        content = self.sha_256_x64_pattern.sub(new_x64_sha_256, content)
        content = self.url_x64_pattern.sub(new_x64_url, content)
        content = self.sha_256_arm64_pattern.sub(new_arm64_sha_256, content)
        content = self.url_arm64_pattern.sub(new_arm64_url, content)

        with open(file_path, 'w') as file:
            file.write(content)

        return True

    @staticmethod
    def update_read_me(sdk_release, latest_sdk_release):
        file_path = 'README.md'

        with open(file_path, 'r') as file:
            content = file.read()

        content = content.replace(str(sdk_release), latest_sdk_release['sdk']['version'])

        with open(file_path, 'w') as file:
            file.write(content)

    @staticmethod
    def _find_download_and_verify_sdk_url(sdk_release, arch):
        sdk_url, sdk_sha_512 = CaskService._find_sdk_url(sdk_release, arch)
        if sdk_url is None:
            Logger.output("Could not find sdk url for sdk_release[{0}]. Skipping".format(sdk_release['sdk']['version']))
            return None, None

        sha_256, sha_512 = CaskService._download_and_calculate_sha256(sdk_url)
        if not sdk_sha_512.casefold() == sha_512.casefold():
            Logger.output("Downloaded sha512[{0}] does not match provided sha512[{1}]. Man-in-the-middle? Skipping".format(sha_512, sdk_sha_512))
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

        with urllib.request.urlopen(url) as r:
            while True:
                chunk = r.read(8192)
                if chunk:
                    sha256.update(chunk)
                    sha512.update(chunk)
                else:
                    break

        return sha256.hexdigest(), sha512.hexdigest()


class Logger:
    @staticmethod
    def log(name, value = ''):
        print('{0}: {1}'.format(name, str(value)))

    @staticmethod
    def output(message):
        print(message)


class GitService:
    def __init__(self, really_push):
        self.really_push = really_push

    def prepare_git_branch(self, file_path, latest_sdk_release):
        branch_name = "update-{0}-to-{1}".format(file_path, latest_sdk_release['sdk']['version'])

        if self.really_push:
            subprocess.run(['git', 'checkout', '-b', branch_name], check = False)
            subprocess.run(['git', 'checkout', branch_name], check = True)
            subprocess.run(['git', 'reset', '--hard', 'origin/master'], check = True)

        return branch_name

    def push_git_branch(self, file_path, sdk_version, latest_sdk_release, branch_name):
        commit_message = '[Auto] update {0} from {1} to {2}'.format(file_path, str(sdk_version), latest_sdk_release['sdk']['version'])

        if self.really_push:
            subprocess.run(['git', 'add', file_path], check = True)
            subprocess.run(['git', 'add', 'README.md'], check = True)
            subprocess.run(['git', 'commit', '-m', commit_message], check = True)
            subprocess.run(['git', 'push', 'origin', '--force', branch_name], check = True)
            subprocess.run(['gh', 'pr', 'create', '--base', 'master', '--head', branch_name, '--title', commit_message, '--body', ''], check = True)


class PreviewUpdater:
    # `version "7.0.100-preview.7.22377.5, 7.0.0-preview.7.22375.6, 8.0.100-rc.1.23463.5"`
    version_pattern = re.compile('version "([0-9.,-preview,-rc]+)"')

    def __init__(self, git_service):
        self.git_service = git_service
        self.cask_service = CaskService(self.version_pattern)

    def run(self):
        for file_path in glob.glob('Casks/*-preview.rb'):
            Logger.output("------------------------------------")
            Logger.output("{0}: Checking for updates  ...".format(file_path))

            (sdk_version, runtime_version) = self._find_preview_versions(file_path)
            Logger.log('sdk_version', sdk_version)
            Logger.log('runtime_version', runtime_version)

            is_arm_supported = self.cask_service.cask_supports_arm(file_path)
            Logger.log('is_arm_supported', is_arm_supported)

            releases_json = self.cask_service.download_release_json(sdk_version)
            (latest_sdk_release, latest_sdk_release_version) = self._find_latest_sdk_preview_release(sdk_version, releases_json)

            if latest_sdk_release is None:
                Logger.output("No latest version found for {0}. Skipping.".format(file_path))
                continue

            if latest_sdk_release_version <= sdk_version:
                Logger.output("Latest version[{0}] is not greater than current version[{1}]. Skipping".format(latest_sdk_release_version, sdk_version))
                continue

            git_branch_name = self.git_service.prepare_git_branch(file_path, latest_sdk_release)

            is_cask_updated = False
            if is_arm_supported:
                is_cask_updated = self.cask_service.update_intel_arm_cask(file_path, latest_sdk_release)
            else:
                is_cask_updated = self.cask_service.update_intel_only_cask(file_path, latest_sdk_release)  

            if is_cask_updated:
                self.cask_service.update_read_me(sdk_version, latest_sdk_release)
                self.git_service.push_git_branch(file_path, sdk_version, latest_sdk_release, git_branch_name)

    def _find_preview_versions(self, file_path):
        with open(file_path, 'r') as file:
            for line in file:
                match = self.version_pattern.search(line.strip())
                if not match:
                    continue

                # split `6.0.100,6.0.0` on comma
                version_split = match.group(1).split(',')

                return PreviewSdkVersion(version_split[0]), PreviewRuntimeVersion(version_split[1])

            raise Exception('Cannot find version in cask: {0}'.format(file_path))

    @staticmethod
    def _find_latest_sdk_preview_release(sdk_version, releases_json):
        sdk_major_minor_version = sdk_version.getMajorMinor()
        sdk_major_minor_version_preview_regex = '^' + sdk_major_minor_version + '.[0-9]{3}-preview.[0-9.]+'
        sdk_major_minor_version_rc_regex = '^' + sdk_major_minor_version + '.[0-9]{3}-rc.[0-9.]+'

        latest_sdk_release = None
        latest_sdk_release_version = None
        releases = releases_json['releases']

        for release in releases:
            match = re.search(sdk_major_minor_version_preview_regex, release['sdk']['version'])
            if not match:
                match = re.search(sdk_major_minor_version_rc_regex, release['sdk']['version'])
            if not match:
                continue

            if latest_sdk_release == None:
                latest_sdk_release = release
                latest_sdk_release_version = PreviewSdkVersion(release['sdk']['version'])
            else:
                release_version = PreviewSdkVersion(release['sdk']['version'])
                if release_version > latest_sdk_release_version:
                    latest_sdk_release = release
                    latest_sdk_release_version = release_version

        return latest_sdk_release, latest_sdk_release_version


class Updater:
    # `version "6.0.100,6.0.0"`
    version_pattern = re.compile('version "([0-9.,]+)"')

    def __init__(self, git_service):
        self.git_service = git_service
        self.cask_service = CaskService(self.version_pattern)

    def run(self):
        for file_path in glob.glob('Casks/*.rb'):
            if 'preview' in file_path:
                continue

            Logger.output("------------------------------------")
            Logger.output("{0}: Checking for updates  ...".format(file_path))

            (sdk_version, runtime_version) = self._find_versions(file_path)
            Logger.log('sdk_version', sdk_version)
            Logger.log('runtime_version', runtime_version)

            is_arm_supported = self.cask_service.cask_supports_arm(file_path)
            Logger.log('is_arm_supported', is_arm_supported)

            releases_json = self.cask_service.download_release_json(sdk_version)
            (latest_sdk_release, latest_sdk_release_version) = self._find_latest_sdk_release(sdk_version, releases_json)

            if latest_sdk_release is None:
                Logger.output("No latest version found for {0}. Skipping.".format(file_path))
                continue

            if latest_sdk_release_version <= sdk_version:
                Logger.output("Latest version[{0}] is not greater than current version[{1}]. Skipping".format(latest_sdk_release_version, sdk_version))
                continue

            git_branch_name = self.git_service.prepare_git_branch(file_path, latest_sdk_release)

            is_cask_updated = False
            if is_arm_supported:
                is_cask_updated = self.cask_service.update_intel_arm_cask(file_path, latest_sdk_release)
            else:
                is_cask_updated = self.cask_service.update_intel_only_cask(file_path, latest_sdk_release)  

            if is_cask_updated:
                self.cask_service.update_read_me(sdk_version, latest_sdk_release)
                self.git_service.push_git_branch(file_path, sdk_version, latest_sdk_release, git_branch_name)

    @staticmethod
    def _find_versions(file_path):
        with open(file_path, 'r') as file:
            for line in file:
                match = Updater.version_pattern.search(line.strip())
                if not match:
                    continue

                # split `6.0.100,6.0.0` on comma
                version_split = match.group(1).split(',')

                return SdkVersion(version_split[0]), RuntimeVersion(version_split[1])

            raise Exception('Cannot find version in cask: {0}'.format(file_path))

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


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--really_push", action='store_true', default=False, help='Indicates whether we really push to git or not')

    args = parser.parse_args()
    git_service = GitService(args.really_push)

    Updater(git_service).run()
    PreviewUpdater(git_service).run()
