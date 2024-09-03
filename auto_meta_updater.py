#!/usr/bin/env python

import argparse
import os
import re
from typing import List, Dict
import subprocess


class MetaCask:
    def __init__(self, meta_cask_name: str, depends_on_filename: str, major: str, minor: str, patch: str):
        self.meta_cask_name = meta_cask_name
        self.depends_on_filename = depends_on_filename
        self.major = major
        self.minor = minor
        self.patch = patch

    def is_newer_than(self, other):
        if self.major > other.major:
            return True
        elif self.major < other.major:
            return False

        if self.minor > other.minor:
            return True
        elif self.minor < other.minor:
            return False

        if self.patch > other.patch:
            return True
        elif self.patch < other.patch:
            return False

        return False

    def __str__(self):
        return f'{self.major}.{self.minor}.{self.patch}'


class DependsOnCask:
    def __init__(self, cask_name: str, sdk_version: str, runtime_version: str, depends_on_cask: str, depends_on_macos: str, is_arm_supported: bool):
        self.cask_name = cask_name
        self.sdk_version = sdk_version
        self.runtime_version = runtime_version
        self.depends_on_cask = depends_on_cask
        self.depends_on_macos = depends_on_macos
        self.is_arm_supported = is_arm_supported


class TemplateService:
    __cask_template_path = "meta-cask.rb.template";
    __cask_x64_template_path = "meta-cask.x64.rb.template";

    def generate(self, meta_cask: MetaCask, depends_on_cask: DependsOnCask) -> str:
        if depends_on_cask.is_arm_supported:
            path = self.__cask_template_path
        else:
            path = self.__cask_x64_template_path

        with open(path, 'r') as file:
            content = file.read()

        content = content.replace('{cask_name}', meta_cask.meta_cask_name)
        content = content.replace('{sdk_version}', depends_on_cask.sdk_version)
        content = content.replace('{runtime_version}', depends_on_cask.runtime_version)
        content = content.replace('{depends_on_cask}', depends_on_cask.depends_on_cask)
        content = content.replace('{depends_on_macos}', depends_on_cask.depends_on_macos)

        return content


class MetaLookupService:
    __cask_version_regex = re.compile(r"(?P<name>dotnet-sdk)(?P<major>\d+)-(?P<minor>\d+)-(?P<patch>\d+)")

    def __init__(self, cask_directory):
        self.cask_directory = cask_directory

    def generate_version_lookup(self) -> Dict[str, MetaCask]:
        result = {}
        casks = self.__list_work_files();
        for cask_filename in casks:
            match = self.__cask_version_regex.search(cask_filename)
            if match is None:
                print("ignored {}: No version match match for filename".format(cask_filename))
                continue

            major = match.group("major")
            minor = match.group("minor")
            patch = match.group("patch")

            meta_cask_name = "{}{}".format(match.group("name"), major)
            current = MetaCask(meta_cask_name, cask_filename, major, minor, patch)

            if meta_cask_name not in result:
                result[meta_cask_name] = current
                continue

            existing = result[meta_cask_name]
            if current.is_newer_than(existing):
                result[meta_cask_name] = current

        return list(result.values())

    def __list_work_files(self):
        result = []
        for file in os.listdir(self.cask_directory):
            if not os.path.isfile(os.path.join(self.cask_directory, file)):
                continue

            if "-preview" in file:
                continue

            if "-rc" in file:
                continue

            # major meta cask only contains 1 dash. eg `dotnet-sdk8`
            if file.count('-') == 1:
                continue

            result.append(file)

        return result


class DependsOnCaskParser:
    __cask_name_pattern = re.compile(r'cask "(?P<cask_name>[a-z0-9-]+)" do')
    __version_pattern = re.compile(r'version "(?P<sdk_version>\d+.\d+.\d+),(?P<runtime_version>\d+.\d+.\d+)"')
    __macos_pattern = re.compile(r'depends_on macos: "(?P<depends_on_macos>[>= :a-z_]+)"')
    __arm_pattern = re.compile(r'arch arm: "arm64", intel: "x64"')

    def __init__(self, cask_directory):
        self.cask_directory = cask_directory

    def parse(self, meta_cask: MetaCask) -> DependsOnCask:
        path = os.path.join(self.cask_directory, meta_cask.depends_on_filename)
        with open(path, 'r') as file:
            content = file.read()

        cask_name_match = self.__cask_name_pattern.search(content)
        if cask_name_match is None:
            return

        version_match = self.__version_pattern.search(content)
        if version_match is None:
            return

        macos_match = self.__macos_pattern.search(content)
        if macos_match is None:
            return

        arm_match = self.__arm_pattern.search(content)
        if arm_match is None:
            is_arm_supported = False
        else:
            is_arm_supported = True

        depends_on_cask_name = meta_cask.depends_on_filename.replace(".rb", "")
        return DependsOnCask(
            depends_on_cask_name, 
            version_match.group("sdk_version"),
            version_match.group("runtime_version"),
            cask_name_match.group("cask_name"),
            macos_match.group("depends_on_macos"),
            is_arm_supported)


class ReadMeUpdater:
    def update(self, meta_cask: MetaCask, depends_on_cask: DependsOnCask):
        file_path = 'README.md'

        with open(file_path, 'r') as file:
            content = file.read()

        content = re.sub(rf'`{meta_cask.meta_cask_name}` \| [\d+.\d+.\d+]+', f'`{meta_cask.meta_cask_name}` | {depends_on_cask.sdk_version}', content)

        with open(file_path, 'w') as file:
            file.write(content)


class GitService:
    def push(self, really_commit, really_push):
        branch_name = 'update-meta-casks'
        commit_message = '[Auto] Update meta casks'

        if really_commit:
            subprocess.run(['git', 'checkout', '-b', branch_name, 'master'], check = False)
            subprocess.run(['git', 'add', '-A'], check = True)
            subprocess.run(['git', 'commit', '-m', commit_message], check = True)

            if really_push:
                subprocess.run(['git', 'push', 'origin', '--force', branch_name], check = True)
                subprocess.run(['gh', 'pr', 'create', '--base', 'master', '--head', branch_name, '--title', commit_message, '--body', ''], check = True)


class MetaUpdater:
    def __init__(self, cask_directory: str, 
        meta_lookup_service: MetaLookupService, 
        depends_on_cask_parser: DependsOnCaskParser, 
        template_service: TemplateService, 
        read_me_updater: ReadMeUpdater):
        self.cask_directory = cask_directory
        self.meta_lookup_service = meta_lookup_service
        self.depends_on_cask_parser = depends_on_cask_parser
        self.template_service = template_service
        self.read_me_updater = read_me_updater

    def run(self):
        meta_casks = self.meta_lookup_service.generate_version_lookup()

        for meta_cask in meta_casks:
            depends_on_cask = depends_on_cask_parser.parse(meta_cask)
            meta_file_content = template_service.generate(meta_cask, depends_on_cask)
            self.write_meta_cask(meta_cask, meta_file_content)
            read_me_updater.update(meta_cask, depends_on_cask)

    def write_meta_cask(self, meta_cask: MetaCask, content: str):
        target_path = "{}.rb".format(os.path.join(self.cask_directory, meta_cask.meta_cask_name))
        with open(target_path, "w") as file:
            file.write(content)


if __name__ == '__main__':
    cask_directory = os.path.join(os.path.dirname(__file__), "Casks")

    meta_lookup_service = MetaLookupService(cask_directory)
    depends_on_cask_parser = DependsOnCaskParser(cask_directory)
    template_service = TemplateService()
    read_me_updater = ReadMeUpdater()

    meta_updater = MetaUpdater(cask_directory, meta_lookup_service, depends_on_cask_parser, template_service, read_me_updater)
    meta_updater.run()

    parser = argparse.ArgumentParser()
    parser.add_argument("--really_commit", action='store_true', default=False, help='Indicates whether we really commit to git or not')
    parser.add_argument("--really_push", action='store_true', default=False, help='Indicates whether we really push to remote or not')

    args = parser.parse_args()

    git_service = GitService()
    git_service.push(args.really_commit, args.really_push)

