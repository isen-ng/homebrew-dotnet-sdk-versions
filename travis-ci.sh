#!/usr/bin/env bash

set -u
set -e

any_casks_modified () {
  [[ -n "$(modified_cask_files)" ]]
}

modified_cask_files () {
  if [[ -z "${MODIFIED_CASK_FILES+defined}" ]]; then
    MODIFIED_CASK_FILES="$(git diff --name-only --diff-filter=AM "${TRAVIS_COMMIT_RANGE}" -- Casks/*.rb)"
    export MODIFIED_CASK_FILES
  fi
  echo "${MODIFIED_CASK_FILES}"
}

if any_casks_modified; then
  modified_casks=($(modified_cask_files))

  echo "Modified casks: ${modified_casks[@]}"
  echo "------------------------------------"

  if [ "${#modified_casks[@]}" -gt 1 ]; then
    echo "More than one cask modified; please submit a pull request for each cask separately."
    exit 0
  fi

  MODIFIED_CASK_FILE=${modified_casks[0]}

  echo "Running brew audit $MODIFIED_CASK_FILE ..."
  echo "------------------------------------"
  brew cask audit $MODIFIED_CASK_FILE

  echo "Running brew style $MODIFIED_CASK_FILE ..."
  echo "------------------------------------"
  brew cask style $MODIFIED_CASK_FILE

  echo "Running brew install $MODIFIED_CASK_FILE ..."
  echo "------------------------------------"
  brew cask install $MODIFIED_CASK_FILE

  echo "Running brew uninstall $MODIFIED_CASK_FILE ..."
  echo "------------------------------------"
  brew cask uninstall $MODIFIED_CASK_FILE

  echo "Running brew zap $MODIFIED_CASK_FILE ..."
  echo "------------------------------------"
  brew cask install $MODIFIED_CASK_FILE
  brew cask zap $MODIFIED_CASK_FILE
fi