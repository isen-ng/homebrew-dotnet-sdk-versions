#!/usr/bin/env bash

set -u
set -e
DRY_RUN=${1:-true}
OWNER="isen-ng"
TITLE_FILTER="[Auto]"
REPO="$OWNER/homebrew-dotnet-sdk-versions"

PR_LIST=$(hub api repos/$REPO/pulls?state=open&base=master)

# reduce the number of elements in the result set, so that it can be passed into functions
PR_LIST=$(echo $PR_LIST | jq -r 'map(. |= {title, url, html_url, number, state, user, head, draft})')
PR_LIST=$(echo $PR_LIST | jq -r 'map(.user |= {login})')
PR_LIST=$(echo $PR_LIST | jq -r 'map(.head |= {ref, sha})')

if [ "$DRY_RUN" == true ]; then
  echo "[debug] List of PRs retrived:"
  echo "$PR_LIST" | jq -r .
fi

FILTERED_PR_LIST=$(echo $PR_LIST | jq -r --arg owner "$OWNER" --arg title_filter "$TITLE_FILTER" '[.[] | select(.user.login == $owner) | select(.draft == false) | select(.title | contains($title_filter))]')

if [ "$DRY_RUN" == true ]; then
  echo "[debug] List of PRs to process:"
  echo "$FILTERED_PR_LIST" | jq -r .
fi

EXIT_CODE=0

for row in $(echo "$FILTERED_PR_LIST" | jq -r '.[] | @base64'); do
  PR=$(echo $row | base64 --decode | jq -r .)

  PR_NUMBER=$(echo $PR | jq -r '.number')
  PR_URL=$(echo $PR | jq -r '.html_url')
  HEAD_REF=$(echo $PR | jq -r '.head.ref')
  HEAD_SHA=$(echo $PR | jq -r '.head.sha')

  echo "[info] Processing PR: $PR_URL"

  # get and reduce the number of elements
  PR_DETAILS=$(hub api repos/$REPO/pulls/$PR_NUMBER)

  # the mergeable flag is not calculated until it is invoked
  # if the invocation above is the first time mergeable is ever invoked, 
  # it will always return `null`. We need to wait for a while, and invoke it again
  sleep 5
  PR_DETAILS=$(hub api repos/$REPO/pulls/$PR_NUMBER)

  PR_DETAILS=$(echo "$PR_DETAILS" | jq -r '. |= {mergeable, merge_commit_sha}')

  if [ "$DRY_RUN" == true ]; then
    echo "[debug] PR details:"
    echo "$PR_DETAILS" | jq -r .
  fi

  # checks whether there is a conflict
  MERGEABLE=$(echo $PR_DETAILS | jq -r '.mergeable')

  if [ "$MERGEABLE" == "null" ]; 
  then
    echo "[warn] PR is still not mergeable yet: $PR_URL"
    continue
  fi

  if [ "$MERGEABLE" != "true" ]; 
  then
    echo "[error] PR has conflicts: $PR_URL"
    EXIT_CODE=1
    continue
  fi
  
  if [ "$DRY_RUN" == true ]; then
    echo "[debug] This is mergeable with SHA: $HEAD_SHA"
  fi

  # this will return pending even if there are no statuses
  # however, we have 1 required status, so we do not accept pending
  # note: `hub ci-status` will return exit code 2 when status is not `success`
  COMMIT_STATUS=$(hub ci-status $HEAD_SHA || if [ $? == 1 ]; then exit 1; fi)

  # pending? maybe try again later
  if [ "$COMMIT_STATUS" == "pending" ];
  then
    echo "[warn] PR still pending, will try again later: $PR_URL"
    continue
  fi

  # ci failed, so fail and try to process another
  if [ "$COMMIT_STATUS" != "success" ];
  then
    echo "[error] PR has ci checks failed: $PR_URL"
    EXIT_CODE=1
    continue
  fi

  if [ "$DRY_RUN" == true ]; then
    echo "[debug] This is mergeable after checking commit status"
  fi

  # merge the PR and delete the branch
  if [ "$DRY_RUN" != true ]; then
    # this merges the PR on github, not locally
    MERGE_RESULT=$(hub api -XPUT "repos/$REPO/pulls/$PR_NUMBER/merge" -f merge_method=squash)
    MERGED=$(echo $MERGE_RESULT | jq -r '.merged')

    # merge failed ???, try to process another
    if [ "$MERGED" != "true" ];
    then
	  echo "[error] PR merge failed ???: $PR_URL"
	  EXIT_CODE=1
	  continue
    fi

	# this deletes the merged branch
	hub push origin :$HEAD_REF
  fi

  if [ "$DRY_RUN" == true ]; then
    echo "[debug] DRY RUN:"
  fi
  echo "[info] PR merged: $PR_URL"
done

exit $EXIT_CODE
