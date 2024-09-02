#!/usr/bin/env python

import argparse
import json
import subprocess
import sys
import time

class PullRequestProcessor:
    def __init__(self, git_service):
        self.git_service = git_service

    def process_ready_pull_requests(self, pull_requests):
        if not pull_requests:
            print('No pull requests to process, finishing.')
            return

        print('Processing these pull requests:')
        for pull_request in pull_requests:
            print (f" - #{pull_request['number']} {pull_request['title']}")

        for pull_request in pull_requests:
            git_service.merge_pull_request(pull_request)
            time.sleep(20)


class GitService:
    def __init__(self, really_merge):
        self.really_merge = really_merge

    def list_pull_requests(self):
        # returns something like this
        # [
        #  {
        #    "mergeStateStatus": "DIRTY"
        #    "number": 289,
        #    "title": "[Auto] update Casks/dotnet-sdk8-preview.rb from 8.0.100-rc.1.23463.5 to 8.0.100-rc.2.23502.2"
        #  },
        #  {
        #    "mergeStateStatus": "CLEAN"
        #    "number": 288,
        #    "title": "[Auto] update Casks/dotnet-sdk6-0-400.rb from 6.0.414 to 6.0.415",
        #    "statusCheckRollup": [
        #      {
        #        "name": "conclusion"
        #        "conclusion": "SUCCESS/FAILURE"
        #      }
        #    ]
        #  }
        #]
        output = subprocess.run(
            ['gh', 'pr', 'list', '--base', 'master', '--state', 'open', '--author', 'isen-ng', '--json', 'number,title,mergeStateStatus,statusCheckRollup'], 
            capture_output = True,
            text = True,
            check = True)

        pull_requests = output.stdout
        pull_requests_json = json.loads(pull_requests)

        # filter for PRs with titles that contain `[Auto]`
        auto_pull_requests = [x for x in pull_requests_json if '[Auto]' in x['title']]

        # filter for PRs that are ready to be merged
        # DIRTY -> There are merge conflicts
        # BLOCKED -> Checks pending or checks failed
        # CLEAN -> PR is ready to be merged
        # BEHIND -> PR is not up to date but it is possible to be ready to be merged

        # find ready PRs by finding PRs that has conclusion = "SUCCESS" (after filtering by "CLEAN" and "BEHIND")
        possible_ready_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] in ('CLEAN', 'BEHIND')]
        ready_pull_requests = [pr for pr in possible_ready_pull_requests if any(item for item in pr['statusCheckRollup'] if item['name'] == 'conclusion' and item['conclusion'] == 'SUCCESS')]

        # find failing PRs by finding PRs that has conclusion = "FAILURE" (after filtering by "BLOCKED")
        failed_or_pending_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] == 'BLOCKED']
        failed_pull_requests = [pr for pr in failed_or_pending_pull_requests if any(item for item in pr['statusCheckRollup'] if item['name'] == 'conclusion' and item['conclusion'] == 'FAILURE')]

        conflicted_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] == 'DIRTY']

        return ready_pull_requests, conflicted_pull_requests, failed_pull_requests

    def merge_pull_request(self, pull_request):
        print (f"Merging pull request: #{pull_request['number']} {pull_request['title']}")

        if not self.really_merge:
            return
    
        subprocess.run(['gh', 'pr', 'merge', str(pull_request['number']), '--squash'], check = True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--really_merge", action='store_true', default=False, help='Indicates whether we really merge the PRs or not')

    args = parser.parse_args()
    git_service = GitService(args.really_merge)
    pull_request_processor = PullRequestProcessor(git_service)

    (ready_pull_requests, conflicted_pull_requests, failed_pull_requests) = git_service.list_pull_requests();
    pull_request_processor.process_ready_pull_requests(ready_pull_requests)

    if conflicted_pull_requests or failed_pull_requests:
        print('There are failed or conflicted PRs. Failing this action to alert author')
        sys.exit(1)

