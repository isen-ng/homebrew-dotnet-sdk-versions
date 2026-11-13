#!/usr/bin/env python

import argparse
import glob
import hashlib
import json
import re
import subprocess
import sys
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
        return (self.major, self.minor, self.feature, self.patch) < (other.major, other.minor, other.feature, other.patch)


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
        return (self.major, self.minor, self.patch) < (other.major, other.minor, other.patch)


class PreviewSdkVersion:
    def __init__(self, version_string):
        # 7.0.100-preview.1.22110.4, 8.0.100-rc.1.23463.5
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        feature = int(version_split[2][0])
        patch = int(version_split[2].split('-')[0][1:])
        is_rc = 'rc' in version_split[2]
        update = int(version_split[3])
        build = int(version_split[4])
        update_specific_build = int(version_split[5])
        self.version_string = version_string
        self.version_tuple = (
            self.major,
            self.minor,
            feature,
            patch,
            is_rc,
            update,
            build,
            update_specific_build
        )

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
        return self.version_tuple < other.version_tuple


class PreviewRuntimeVersion:
    def __init__(self, version_string):
        # 7.0.0-preview.7.22375.6
        version_split = version_string.split('.')
        self.major = int(version_split[0])
        self.minor = int(version_split[1])
        patch = int(version_split[2].split('-')[0])
        is_rc = 'rc' in version_split[2]
        update = int(version_split[3])
        build = int(version_split[4])
        update_specific_build = int(version_split[5])
        self.version_string = version_string
        self.version_tuple = (
            self.major,
            self.minor,
            patch,
            is_rc,
            update,
            build,
            update_specific_build
        )

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
        return self.version_tuple < other.version_tuple


class CaskService:
    # `sha256 "d290cefddb4fbdf1215724c049d86b4ce09f5dc2c5a658e3c1645c368f34c31a"`
    sha_256_pattern = re.compile('sha256 "([0-9a-z]+)"')

    # `url "https://download.visualstudio.microsoft.com/download/pr/38102737-cb48-46c2-8f52-fb7102b50ae7/d81958d71c3c2679796e1ecfbd9cc903/dotnet-sdk-#{version.csv.first}-osx-x64.pkg"`
    url_pattern = re.compile(r'url "([^\s]+)"')

    sha_256_x64_pattern = re.compile('sha256_x64 = "([0-9a-z]+)"')
    sha_256_arm64_pattern = re.compile('sha256_arm64 = "([0-9a-z]+)"')
    url_x64_pattern = re.compile(r'url_x64 = "([^\s]+)"')
    url_arm64_pattern = re.compile(r'url_arm64 = "([^\s]+)"')

    releases_json_url = 'https://builds.dotnet.microsoft.com/dotnet/release-metadata/{}/releases.json'

    # Shared across updaters so each channel's releases.json is downloaded at most once per run.
    _releases_json_cache = {}

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

        cache = CaskService._releases_json_cache
        if sdk_major_minor_version not in cache:
            url = CaskService.releases_json_url.format(sdk_major_minor_version)
            Logger.log('downloading', url)
            with urllib.request.urlopen(url, timeout = 60) as f:
                cache[sdk_major_minor_version] = json.loads(f.read().decode('utf-8'))

        return cache[sdk_major_minor_version]

    @staticmethod
    def cask_is_meta(file_path):
        with open(file_path, 'r') as file:
            for line in file:
                if 'stage_only true' in line.strip():
                    return True
        return False

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

        return None, None

    @staticmethod
    def _download_and_calculate_sha256(url):
        sha256 = hashlib.sha256()
        sha512 = hashlib.sha512()

        with urllib.request.urlopen(url, timeout = 120) as r:
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
        self.open_pull_requests = self._list_open_pull_requests() if really_push else []

    @staticmethod
    def _list_open_pull_requests():
        output = subprocess.run(
            ['gh', 'pr', 'list', '--base', 'master', '--state', 'open', '--limit', '200', '--json', 'number,headRefName'],
            capture_output = True,
            text = True,
            check = True)
        return json.loads(output.stdout)

    @staticmethod
    def branch_name(file_path, latest_sdk_release):
        return "update-{0}-to-{1}".format(file_path, latest_sdk_release['sdk']['version'])

    @staticmethod
    def _branch_prefix(file_path):
        return "update-{0}-to-".format(file_path)

    def has_open_pull_request(self, branch_name):
        return any(pr['headRefName'] == branch_name for pr in self.open_pull_requests)

    def prepare_git_branch(self, branch_name):
        if self.really_push:
            subprocess.run(['git', 'checkout', '--force', '-B', branch_name, 'origin/master'], check = True)

    def push_git_branch(self, file_path, sdk_version, latest_sdk_release, branch_name):
        commit_message = '[Auto] update {0} from {1} to {2}'.format(file_path, str(sdk_version), latest_sdk_release['sdk']['version'])

        if not self.really_push:
            return None

        subprocess.run(['git', 'add', file_path], check = True)
        subprocess.run(['git', 'commit', '-m', commit_message], check = True)
        subprocess.run(['git', 'push', 'origin', '--force', branch_name], check = True)
        output = subprocess.run(
            ['gh', 'pr', 'create', '--base', 'master', '--head', branch_name, '--title', commit_message, '--body', ''],
            capture_output = True,
            text = True,
            check = True)
        pull_request_url = output.stdout.strip()
        Logger.log('created pull request', pull_request_url)
        return pull_request_url

    def close_superseded_pull_requests(self, file_path, branch_name, pull_request_url):
        prefix = self._branch_prefix(file_path)
        for pull_request in self.open_pull_requests:
            head = pull_request['headRefName']
            if not head.startswith(prefix) or head == branch_name:
                continue

            Logger.output("Closing superseded pull request #{0} ({1})".format(pull_request['number'], head))
            if self.really_push:
                subprocess.run(
                    ['gh', 'pr', 'close', str(pull_request['number']), '--delete-branch',
                     '--comment', 'Superseded by {0}'.format(pull_request_url)],
                    check = True)


def update_cask(file_path, sdk_version, latest_sdk_release, is_arm_supported, cask_service, git_service):
    branch_name = git_service.branch_name(file_path, latest_sdk_release)
    if git_service.has_open_pull_request(branch_name):
        Logger.output("An open pull request for branch[{0}] already exists. Skipping".format(branch_name))
        return

    git_service.prepare_git_branch(branch_name)

    if is_arm_supported:
        is_cask_updated = cask_service.update_intel_arm_cask(file_path, latest_sdk_release)
    else:
        is_cask_updated = cask_service.update_intel_only_cask(file_path, latest_sdk_release)

    if not is_cask_updated:
        return

    pull_request_url = git_service.push_git_branch(file_path, sdk_version, latest_sdk_release, branch_name)
    git_service.close_superseded_pull_requests(file_path, branch_name, pull_request_url)


class PreviewUpdater:
    # `version "7.0.100-preview.7.22377.5, 7.0.0-preview.7.22375.6, 8.0.100-rc.1.23463.5"`
    version_pattern = re.compile('version "([0-9.,-preview,-rc]+)"')

    def __init__(self, git_service):
        self.git_service = git_service
        self.cask_service = CaskService(self.version_pattern)

    def run(self):
        failed_casks = []
        for file_path in sorted(glob.glob('Casks/*-preview.rb')):
            if self.cask_service.cask_is_meta(file_path):
                continue

            try:
                self._run_cask(file_path)
            except Exception as e:
                Logger.output("{0}: Failed to update: {1!r}".format(file_path, e))
                failed_casks.append(file_path)

        return failed_casks

    def _run_cask(self, file_path):
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
            return

        if latest_sdk_release_version <= sdk_version:
            Logger.output("Latest version[{0}] is not greater than current version[{1}]. Skipping".format(latest_sdk_release_version, sdk_version))
            return

        update_cask(file_path, sdk_version, latest_sdk_release, is_arm_supported, self.cask_service, self.git_service)

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
        failed_casks = []
        for file_path in sorted(glob.glob('Casks/*.rb')):
            if 'preview' in file_path:
                continue
            if self.cask_service.cask_is_meta(file_path):
                continue

            try:
                self._run_cask(file_path)
            except Exception as e:
                Logger.output("{0}: Failed to update: {1!r}".format(file_path, e))
                failed_casks.append(file_path)

        return failed_casks

    def _run_cask(self, file_path):
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
            return

        if latest_sdk_release_version <= sdk_version:
            Logger.output("Latest version[{0}] is not greater than current version[{1}]. Skipping".format(latest_sdk_release_version, sdk_version))
            return

        update_cask(file_path, sdk_version, latest_sdk_release, is_arm_supported, self.cask_service, self.git_service)

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
            # 'sdks' (plural) contains all SDK feature bands shipped with this runtime release.
            # Fall back to [release['sdk']] for older releases that don't have the 'sdks' key.
            sdk_candidates = release.get('sdks') or [release['sdk']]

            for sdk_candidate in sdk_candidates:
                match = re.search(sdk_major_minor_feature_version_regex, sdk_candidate['version'])
                if not match:
                    continue

                if latest_sdk_release is None:
                    latest_sdk_release = {'sdk': sdk_candidate, 'runtime': release['runtime']}
                    latest_sdk_release_version = SdkVersion(sdk_candidate['version'])
                else:
                    release_version = SdkVersion(sdk_candidate['version'])
                    if release_version > latest_sdk_release_version:
                        latest_sdk_release = {'sdk': sdk_candidate, 'runtime': release['runtime']}
                        latest_sdk_release_version = release_version

        return latest_sdk_release, latest_sdk_release_version


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--really_push", action='store_true', default=False, help='Indicates whether we really push to git or not')

    args = parser.parse_args()
    git_service = GitService(args.really_push)

    failed_casks = Updater(git_service).run() + PreviewUpdater(git_service).run()

    if failed_casks:
        Logger.output("------------------------------------")
        Logger.output("Failed to update these casks:")
        for file_path in failed_casks:
            Logger.output(" - {0}".format(file_path))
        sys.exit(1)
