#!/usr/bin/env python

import argparse
import glob
import json
import os
import re
import subprocess


class Logger:
    @staticmethod
    def log(name, value = ''):
        print('{0}: {1}'.format(name, str(value)))

    @staticmethod
    def output(message):
        print(message)


class CaskVersionReader:
    # `version "10.0.100,10.0.0"`, `version "11.0.100-rc.2.25502.107,11.0.0-rc.2.25502.107"`
    version_pattern = re.compile(r'^\s*version "([^",]+),')

    def __init__(self, cask_directory):
        self.cask_directory = cask_directory

    def read(self):
        versions = {}
        for file_path in sorted(glob.glob(os.path.join(self.cask_directory, '*.rb'))):
            cask_name = os.path.basename(file_path)[:-len('.rb')]
            with open(file_path, 'r') as file:
                for line in file:
                    match = self.version_pattern.match(line)
                    if match:
                        versions[cask_name] = match.group(1)
                        break

            if cask_name not in versions:
                Logger.output("Could not find version in {0}. Skipping".format(file_path))

        return versions


class ReadMeUpdater:
    # `| `dotnet-sdk10-0-200` | 10.0.204 | x64 & arm64 | |`: cask name in the first column, sdk version in the second
    row_pattern = re.compile(r'^(\|\s*`(?P<cask_name>[a-z0-9-]+)`\s*\|)(?P<cell>[^|\n]*)(\|)', re.MULTILINE)

    def __init__(self, file_path):
        self.file_path = file_path

    def update(self, versions):
        with open(self.file_path, 'r') as file:
            content = file.read()

        rows_found = set()

        def replace_cell(match):
            cask_name = match.group('cask_name')
            rows_found.add(cask_name)
            if cask_name not in versions:
                Logger.output("README row {0} has no cask. Leaving it unchanged".format(cask_name))
                return match.group(0)

            old_cell = match.group('cell')
            # keep the column width when the new version fits, so the table stays aligned
            new_cell = ' {0} '.format(versions[cask_name]).ljust(len(old_cell))
            if new_cell.strip() != old_cell.strip():
                Logger.log(cask_name, '{0} -> {1}'.format(old_cell.strip(), versions[cask_name]))
            return match.group(1) + new_cell + match.group(4)

        content = self.row_pattern.sub(replace_cell, content)

        for cask_name in sorted(set(versions) - rows_found):
            Logger.output("Cask {0} has no README row. Add one by hand".format(cask_name))

        with open(self.file_path, 'w') as file:
            file.write(content)


class GitService:
    branch_name = 'update-readme'
    commit_message = '[Auto] Update README'

    def push(self, really_commit, really_push):
        process = subprocess.run(['git', 'status', '--porcelain', 'README.md'], check = True, capture_output = True, text = True)
        if not process.stdout:
            Logger.output("README is up to date")
            return

        if not really_commit:
            return

        subprocess.run(['git', 'checkout', '-B', self.branch_name], check = True)
        subprocess.run(['git', 'add', 'README.md'], check = True)
        subprocess.run(['git', 'commit', '-m', self.commit_message], check = True)

        if not really_push:
            return

        # Re-pushing identical content would only restart CI on the open pull request.
        remote_branch_exists = subprocess.run(['git', 'fetch', 'origin', self.branch_name], check = False).returncode == 0
        if remote_branch_exists and subprocess.run(['git', 'diff', '--quiet', 'FETCH_HEAD', 'HEAD'], check = False).returncode == 0:
            Logger.output("Remote branch[{0}] already has these changes. Skipping push".format(self.branch_name))
        else:
            subprocess.run(['git', 'push', 'origin', '--force', self.branch_name], check = True)

        output = subprocess.run(
            ['gh', 'pr', 'list', '--base', 'master', '--head', self.branch_name, '--state', 'open', '--json', 'number'],
            capture_output = True,
            text = True,
            check = True)
        open_pull_requests = json.loads(output.stdout)
        if open_pull_requests:
            Logger.output("An open pull request for branch[{0}] already exists".format(self.branch_name))
            self.enable_auto_merge(open_pull_requests[0]['number'], required = False)
            return

        output = subprocess.run(
            ['gh', 'pr', 'create', '--base', 'master', '--head', self.branch_name, '--title', self.commit_message, '--body', ''],
            capture_output = True,
            text = True,
            check = True)
        pull_request_url = output.stdout.strip()
        Logger.log('created pull request', pull_request_url)
        self.enable_auto_merge(pull_request_url)

    @staticmethod
    def enable_auto_merge(pull_request, required = True):
        # GitHub merges the pull request once the required `conclusion` check passes
        result = subprocess.run(['gh', 'pr', 'merge', str(pull_request), '--auto', '--squash'], check = required)
        if result.returncode != 0:
            Logger.output("Could not enable auto-merge for pull request[{0}]".format(pull_request))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description = 'Sets the .NET SDK version of every README row to the version in its cask')
    parser.add_argument("--really_commit", action='store_true', default=False, help='Indicates whether we really commit to git or not')
    parser.add_argument("--really_push", action='store_true', default=False, help='Indicates whether we really push to remote or not')

    args = parser.parse_args()

    root_directory = os.path.dirname(os.path.abspath(__file__))
    versions = CaskVersionReader(os.path.join(root_directory, 'Casks')).read()
    ReadMeUpdater(os.path.join(root_directory, 'README.md')).update(versions)

    GitService().push(args.really_commit, args.really_push)
