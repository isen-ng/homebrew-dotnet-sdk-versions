#!/usr/bin/env python

import json
import subprocess
import sys


class GitService:
    @staticmethod
    def conclusion_of(pull_request):
        # statusCheckRollup mixes check runs (`name`, `conclusion`) and commit statuses (`context`, `state`)
        for item in pull_request.get('statusCheckRollup') or []:
            if item.get('name') == 'conclusion':
                return item.get('conclusion')
        return None

    def list_auto_pull_requests(self):
        output = subprocess.run(
            ['gh', 'pr', 'list', '--base', 'master', '--state', 'open', '--author', 'isen-ng', '--limit', '200',
             '--json', 'number,title,mergeStateStatus,statusCheckRollup,autoMergeRequest'],
            capture_output = True,
            text = True,
            check = True)

        return [pr for pr in json.loads(output.stdout) if '[Auto]' in pr['title']]


class PullRequestChecker:
    def __init__(self, git_service):
        self.git_service = git_service

    def check(self, pull_requests):
        failed = []
        conflicted = []
        not_merged = []

        # mergeStateStatus values:
        # DIRTY -> There are merge conflicts
        # BLOCKED -> Checks pending or checks failed
        # CLEAN -> PR is ready to be merged
        # BEHIND -> PR is not up to date with master
        for pr in pull_requests:
            conclusion = self.git_service.conclusion_of(pr)
            if conclusion == 'FAILURE':
                failed.append(pr)
            elif pr['mergeStateStatus'] == 'DIRTY':
                conflicted.append(pr)
            elif conclusion == 'SUCCESS' and pr['mergeStateStatus'] in ('CLEAN', 'BEHIND'):
                # auto-merge merges these right after the check passes, so one still open needs attention
                not_merged.append(pr)
            else:
                print(f"Waiting on #{pr['number']} {pr['title']} (mergeStateStatus={pr['mergeStateStatus']}, conclusion={conclusion})")

            if pr.get('autoMergeRequest') is None:
                print(f"Auto-merge is not enabled on #{pr['number']} {pr['title']}")

        return failed, conflicted, not_merged


def print_pull_requests(heading, pull_requests):
    if not pull_requests:
        return

    print(heading)
    for pull_request in pull_requests:
        print(f" - #{pull_request['number']} {pull_request['title']}")


if __name__ == "__main__":
    git_service = GitService()
    pull_requests = git_service.list_auto_pull_requests()
    if not pull_requests:
        print('No open [Auto] pull requests.')
        sys.exit(0)

    failed, conflicted, not_merged = PullRequestChecker(git_service).check(pull_requests)

    print_pull_requests('Failed checks:', failed)
    print_pull_requests('Conflicted:', conflicted)
    print_pull_requests('Checks passed but not merged (is auto-merge enabled?):', not_merged)

    if failed or conflicted or not_merged:
        print('There are failed, conflicted or unmerged PRs. Failing this action to alert author')
        sys.exit(1)
