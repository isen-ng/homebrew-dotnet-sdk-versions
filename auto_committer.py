#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys

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
        # auto_pull_requests = [x for x in pull_requests_json if '[Auto]' in x['title']]
        auto_pull_requests = pull_requests_json
        # print(json.dumps(pull_requests_json, indent=2))

        # filter for PRs that are ready to be merged
        # DIRTY -> There are merge conflicts
        # BLOCKED -> Checks pending or checks failed
        # CLEAN -> PR is ready to be merged
        ready_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] == 'CLEAN']
        conflicted_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] == 'DIRTY']

        failed_or_pending_pull_requests = [x for x in auto_pull_requests if x['mergeStateStatus'] == 'BLOCKED']
        failed_pull_requests = [pr for pr in failed_or_pending_pull_requests if any(item for item in pr['statusCheckRollup'] if item['name'] == 'conclusion' and item['conclusion'] == 'FAILURE')]

        # remove useless keys, for better display later
        ready_pull_requests = Utils._remove_keys(ready_pull_requests, 'mergeStateStatus', 'statusCheckRollup')
        conflicted_pull_requests = Utils._remove_keys(conflicted_pull_requests, 'mergeStateStatus', 'statusCheckRollup')
        failed_pull_requests = Utils._remove_keys(failed_pull_requests, 'mergeStateStatus', 'statusCheckRollup')

        return ready_pull_requests, conflicted_pull_requests, failed_pull_requests

    def merge_pull_request(self, pull_request):
        print (f"Merging pull request: #{pull_request['number']} {pull_request['title']}")

        if not self.really_merge:
            return
    
        subprocess.run(['gh', 'pr', 'merge', pull_request['number']], check = True)


class Utils:
    @staticmethod
    def _remove_keys(pull_requests, *args):
        result = pull_requests
        for keyToRemove in args:
            result = Utils._remove_key(result, keyToRemove)

        return result

    @staticmethod
    def _remove_key(pull_requests, keyToRemove):
        return [{key: value for key, value in pull_request.items() if key != keyToRemove} for pull_request in pull_requests]


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

