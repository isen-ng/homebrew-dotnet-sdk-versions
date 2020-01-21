#!/usr/bin/env bash

set -u
set -e
DRY_RUN=${1:-true}

function check_fork {
  if ! git ls-remote fork > /dev/null 2>&1; then
    git remote add fork "https://github.com/$GITHUB_USER/homebrew-dotnet-sdk-versions.git"
  fi
}

function update_casks {
  FILE_VERSION_REGEX="dotnet-sdk-([0-9\.]{5,8}).rb"
  README_FILENAME="../README.md"

  for FILENAME in *.rb; do
    echo "$FILENAME: Checking for updates  ..."

    FILE_VERSION=""

    if [[ $FILENAME =~ $FILE_VERSION_REGEX ]]
    then
        FILE_VERSION="${BASH_REMATCH[1]}"
    else
        echo "$FILENAME is not a dotnet-sdk cask"
        continue
    fi

    CASK_VERSION=$(cat $FILENAME | grep -e "version '*'" | awk '{print $2}' | tr -d "'")
    CASK_SHA256=$(cat $FILENAME | grep -e "sha256 '*'" | awk '{print $2}' | tr -d "'")
    CASK_URL=$(cat $FILENAME | grep -e "url '*'" | awk '{print $2}' | tr -d "'")
    CURRENT_SDK_VERSION=$(echo $CASK_VERSION | cut -d, -f1)
    CURRENT_RUNTIME_VERSION=$(echo $CASK_VERSION | cut -d, -f2)
    CURRENT_SDK_MINOR_VERSION=$(echo $CURRENT_SDK_VERSION | cut -d. -f1,2)
    CURRENT_SDK_PATCH_VERSION=$(echo $CURRENT_SDK_VERSION | cut -d. -f3)
    CURRENT_SDK_PATCH_MAJOR_VERSION="${CURRENT_SDK_PATCH_VERSION:0:1}"

    if [ "$DRY_RUN" = true ]; then
      echo "CASK_VERSION: $CASK_VERSION"
      echo "CASK_SHA256: $CASK_SHA256"
      echo "CASK_URL: $CASK_URL"
      echo "CURRENT_SDK_VERSION: $CURRENT_SDK_VERSION"
      echo "CURRENT_RUNTIME_VERSION: $CURRENT_RUNTIME_VERSION"
      echo "CURRENT_SDK_MINOR_VERSION: $CURRENT_SDK_MINOR_VERSION"
      echo "CURRENT_SDK_PATCH_VERSION: $CURRENT_SDK_PATCH_VERSION"
      echo "CURRENT_SDK_PATCH_MAJOR_VERSION: $CURRENT_SDK_PATCH_MAJOR_VERSION"
      echo "-----------------------------------------------------------------"
    fi

    RELEASES_URL="https://raw.githubusercontent.com/dotnet/core/master/release-notes/$CURRENT_SDK_MINOR_VERSION/releases.json"
    RELEASES_JSON=$(curl --silent "$RELEASES_URL")

    # look for SDK releases
    SDK_RELEASES=$(echo "$RELEASES_JSON" | jq --arg v "^2.2.$CURRENT_SDK_PATCH_MAJOR_VERSION[0-9]{2}$" '[.releases[] | select(."release-version" | test ($v))]')
    LATEST_SDK_RELEASE=$(echo $SDK_RELEASES | jq 'max_by(."release-version" | [splits("[.]")] | map(tonumber))')

    LATEST_SDK_RELEASE_SDK_VERSION=$(echo $LATEST_SDK_RELEASE | jq '.sdk.version | select(.!=null)' | tr -d "\"")
    LATEST_SDK_RELEASE_RUNTIME_VERSION=$(echo $LATEST_SDK_RELEASE | jq '.sdk."runtime-version" | select(.!=null)' | tr -d "\"")
    LATEST_SDK_RELEASE_URL=$(echo $LATEST_SDK_RELEASE | jq '.sdk.files[]? | select(.name == "dotnet-sdk-osx-x64.pkg").url' | tr -d "\"")
    LATEST_SDK_RELEASE_HASH=$(echo $LATEST_SDK_RELEASE | jq '.sdk.files[]? | select(.name == "dotnet-sdk-osx-x64.pkg").hash' | tr -d "\"")

    if [ "$DRY_RUN" = true ]; then
      echo "LATEST_SDK_RELEASE_SDK_VERSION: $LATEST_SDK_RELEASE_SDK_VERSION"
      echo "LATEST_SDK_RELEASE_RUNTIME_VERSION: $LATEST_SDK_RELEASE_RUNTIME_VERSION"
      echo "LATEST_SDK_RELEASE_URL: $LATEST_SDK_RELEASE_URL"
      echo "LATEST_SDK_RELEASE_HASH: $LATEST_SDK_RELEASE_HASH"
      echo "-----------------------------------------------------------------"
    fi

    # look for runtime releases
    RUNTIME_RELEASES=$(echo "$RELEASES_JSON" | jq --arg v "^[0-9]{1}.[0-9]{1}.[0-9]{1,2}$" '[.releases[] | select(."release-version" | test ($v))]')
    LATEST_RUNTIME_RELEASE=$(echo $RUNTIME_RELEASES | jq 'max_by(."release-version" | [splits("[.]")] | map(tonumber))')
    LATEST_RUNTIME_SDK_RELEASE=$(echo $LATEST_RUNTIME_RELEASE | jq --arg v "^[0-9]{1}.[0-9]{1}.$CURRENT_SDK_PATCH_MAJOR_VERSION[0-9]{2}$" '.sdks[]? | select(."version" | test($v))')

    LATEST_RUNTIME_RELEASE_SDK_VERSION=$(echo $LATEST_RUNTIME_SDK_RELEASE | jq '.version' | tr -d "\"")
    LATEST_RUNTIME_RELEASE_RUNTIME_VERSION=$(echo $LATEST_RUNTIME_RELEASE | jq '."release-version"' | tr -d "\"")
    LATEST_RUNTIME_RELEASE_URL=$(echo $LATEST_RUNTIME_SDK_RELEASE | jq '.files[]? | select(.name == "dotnet-sdk-osx-x64.pkg").url' | tr -d "\"")
    LATEST_RUNTIME_RELEASE_HASH=$(echo $LATEST_RUNTIME_SDK_RELEASE | jq '.files[]? | select(.name == "dotnet-sdk-osx-x64.pkg").hash' | tr -d "\"")
    
    if [ "$DRY_RUN" = true ]; then
      echo "LATEST_RUNTIME_RELEASE_SDK_VERSION: $LATEST_RUNTIME_RELEASE_SDK_VERSION"
      echo "LATEST_RUNTIME_RELEASE_RUNTIME_VERSION: $LATEST_RUNTIME_RELEASE_RUNTIME_VERSION"
      echo "LATEST_RUNTIME_RELEASE_URL: $LATEST_RUNTIME_RELEASE_URL"
      echo "LATEST_RUNTIME_RELEASE_HASH: $LATEST_RUNTIME_RELEASE_HASH"
      echo "-----------------------------------------------------------------"
    fi

    # determine latest release
    LATEST_SDK_VERSION=$LATEST_SDK_RELEASE_SDK_VERSION
    LATEST_RUNTIME_VERSION=$LATEST_SDK_RELEASE_RUNTIME_VERSION
    LATEST_SDK_URL=$LATEST_SDK_RELEASE_URL
    LATEST_SDK_HASH=$LATEST_SDK_RELEASE_HASH

    if [ ! -z "$LATEST_RUNTIME_RELEASE_SDK_VERSION" ] && [ ! -z "$LATEST_RUNTIME_RELEASE_RUNTIME_VERSION" ] && [ ! -z "$LATEST_RUNTIME_RELEASE_URL" ] && [ ! -z "$LATEST_RUNTIME_RELEASE_HASH" ]; then
      # if SDK release does not exist, then simply set runtime release as latest release
      if [ -z "$LATEST_SDK_VERSION" ]; then
        LATEST_SDK_VERSION=$LATEST_RUNTIME_RELEASE_SDK_VERSION
        LATEST_RUNTIME_VERSION=$LATEST_RUNTIME_RELEASE_RUNTIME_VERSION
        LATEST_SDK_URL=$LATEST_RUNTIME_RELEASE_URL
        LATEST_SDK_HASH=$LATEST_RUNTIME_RELEASE_HASH
      else
        # otherwise compare latest patch
        SDK_RELEASE_SDK_PATCH_VERSION=$(echo $LATEST_SDK_VERSION | cut -d. -f3)
        RUNTIME_RELEASE_SDK_PATCH_VERSION=$(echo $LATEST_RUNTIME_RELEASE_SDK_VERSION | cut -d. -f3)

        if [ "$RUNTIME_RELEASE_SDK_PATCH_VERSION" -gt "$SDK_RELEASE_SDK_PATCH_VERSION" ]; then
          LATEST_SDK_VERSION=$LATEST_RUNTIME_RELEASE_SDK_VERSION
          LATEST_RUNTIME_VERSION=$LATEST_RUNTIME_RELEASE_RUNTIME_VERSION
          LATEST_SDK_URL=$LATEST_RUNTIME_RELEASE_URL
          LATEST_SDK_HASH=$LATEST_RUNTIME_RELEASE_HASH
        fi
      fi
    fi

    if [ "$DRY_RUN" = true ]; then
      echo "LATEST_SDK_VERSION: $LATEST_SDK_VERSION"
      echo "LATEST_RUNTIME_VERSION: $LATEST_RUNTIME_VERSION"
      echo "LATEST_SDK_URL: $LATEST_SDK_URL"
      echo "LATEST_SDK_HASH: $LATEST_SDK_HASH"
      echo "-----------------------------------------------------------------"
    fi

    # if there is no latest version found, then there is nothing to update
    if [ -z "$LATEST_SDK_VERSION" ] || [ -z "$LATEST_RUNTIME_VERSION" ] || [ -z "$LATEST_SDK_URL" ] || [ -z "$LATEST_SDK_HASH" ]; then
      echo "No latest version found for $FILENAME in $RELEASES_URL"
      continue
    fi

    # compare latest release with current release
    CURRENT_PATCH_VERSION=$(echo $CURRENT_SDK_PATCH_VERSION | cut -d. -f3)
    LATEST_PATCH_VERSION=$(echo $LATEST_SDK_VERSION | cut -d. -f3)

    if [ "$DRY_RUN" = true ]; then
      echo "CURRENT_PATCH_VERSION: $CURRENT_PATCH_VERSION"
      echo "LATEST_PATCH_VERSION: $LATEST_PATCH_VERSION"
      echo "-----------------------------------------------------------------"
    fi

    if [ "$CURRENT_PATCH_VERSION" -gt "$LATEST_PATCH_VERSION" ]; then
      echo "$FILENAME: Current [$CURRENT_SDK_VERSION] is greater than latest version [$LATEST_SDK_VERSION] in $RELEASES_URL"
      continue
    fi

    if [ "$CURRENT_PATCH_VERSION" -eq "$LATEST_PATCH_VERSION" ] && [ "$CASK_URL" == "$LATEST_SDK_URL" ]; then
      echo "$FILENAME: Current [$CURRENT_SDK_VERSION] is the latest version. Nothing to update"
      continue
    fi

    echo "$FILENAME: Updating to $LATEST_SDK_VERSION ..."
    GIT_BRANCH_NAME="update-$FILENAME-to-$LATEST_SDK_VERSION"

    if [ "$DRY_RUN" != true ]; then
      git checkout "$GIT_BRANCH_NAME" || git checkout -b "$GIT_BRANCH_NAME"
      git reset --hard origin/master
    fi

    # download the sdk file to calculate its sha256
    wget -O "$LATEST_SDK_VERSION.pkg" "$LATEST_SDK_URL"
    LATEST_SDK_SHA256=$(sha256sum "$LATEST_SDK_VERSION.pkg" | cut -d" " -f1)
    rm -f "$LATEST_SDK_VERSION.pkg"
    if [ "$DRY_RUN" = true ]; then
      echo "LATEST_SDK_SHA256: $LATEST_SDK_SHA256"
    fi

    # update values
    LATEST_CASK_VERSION="$LATEST_SDK_VERSION,$LATEST_RUNTIME_VERSION"
    if [ "$DRY_RUN" = true ]; then
      echo "LATEST_CASK_VERSION: $LATEST_CASK_VERSION"
    fi
    sed -i "s@${CASK_VERSION}@${LATEST_CASK_VERSION}@g" $FILENAME
    sed -i "s@${CASK_SHA256}@${LATEST_SDK_SHA256}@g" $FILENAME
    sed -i "s@${CASK_URL}@${LATEST_SDK_URL}@g" $FILENAME

    # update readme
    # todo: use a template instead of sed
    sed -i "s@dotnet ${CURRENT_SDK_VERSION}@dotnet ${LATEST_SDK_VERSION}@g" $README_FILENAME

    if [ "$DRY_RUN" != true ]; then
      check_fork

      git add $FILENAME
      git add $README_FILENAME
      git commit -m "update $FILENAME from $CASK_VERSION to $LATEST_CASK_VERSION"
      git push fork "$GIT_BRANCH_NAME" --force
      hub pull-request --base isen-ng:master --head "$GIT_BRANCH_NAME" -m "[Auto] Update \"$FILENAME\" to $LATEST_SDK_VERSION"
    fi
  done
}

cd Casks

if [ "$DRY_RUN" != true ]; then
  git fetch --all
  git reset --hard origin/master
fi

update_casks

cd -