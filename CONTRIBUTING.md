# Contribution guide

## Automatic updates

Each working cask will be updated weekly automatically by running `auto_updater.sh` through a 
CircleCi scheduled workflow.

The script will enumerate over each cask, search through the releases in their respective 
`releases.json` and author a pull request if there is a newer version released.

All the releases and their notes are published [here](https://github.com/dotnet/core/tree/master/release-notes).

## Automatic commits

Each day of the week, except the day that the auto updater is running, the `auto_committer.sh` script is ran
through a Github Actions scheduled workflow.

This script will comb through existing pull requests created by `auto-updater.sh`, check their status, and if
they are mergeable, (squash and) merge the commit. Only those with conflicts, or merge issues will require
manual intervention from the author. In this case, the author will be notified via a failed run.

## Adding a new cask

Install the necessary tools if you already haven't

```
./brew_install_necessary.sh
```

Use the existing casks as a template and fill in the version number till the patch major version. The filename and cask name must match, according to BrewCask's rules.

The runtime version, `sha256`, and the `url` isn't important and can be filled with placeholder text.

```
cask 'dotnet-sdk-2.99.400' do
  version '2.99.400,2.0.0'
  sha256 '?????'

  url '???'
  

  ... so on and so forth ...

end
```

Then run `auto_updater.sh` in dry run mode.

```
# passing in no arguments defaults to dry run mode
./auto_updater.sh
```

The dry run mode will update all casks, including the cask you've just added without committing and publishing pull
requests.

Branch out, add the file you want to commit, commit, and push.

```
git checkout -b new-cask/dotnet-sdk-2.99.400
git add Casks/dotnet-sdk-2.99.400.rb
git commit -m "Add support for dotnet-sdk-2.99.400.rb"
git push fork new-cask/dotnet-sdk-2.99.400
```

## Offical cask

If there is a need to refer to the official cask, it can be found here:

https://github.com/Homebrew/homebrew-cask/blob/master/Casks/dotnet-sdk.rb
