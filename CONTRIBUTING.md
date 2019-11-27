# Contribution guide

## Automatic updates

Each working cask will be updated weekly automatically by running `auto_updater.sh` through a 
CircleCi workflow schedule.

The script will enumerate over each cask, search through the releases in their respective 
`releases.json` and author a pull request if there is a newer version released.

All the releases and their notes are published [here](https://github.com/dotnet/core/tree/master/release-notes).

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

TESTINGG
