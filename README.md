# dotnet-sdk versions tap

[![Continuous-integration](https://img.shields.io/travis/com/isen-ng/homebrew-dotnet-sdk-versions/master?label=continuous-integration)](https://travis-ci.com/isen-ng/homebrew-dotnet-sdk-versions)
[![Auto-updater](https://img.shields.io/circleci/build/github/isen-ng/homebrew-dotnet-sdk-versions/master?label=auto-updater)](https://circleci.com/gh/isen-ng/homebrew-dotnet-sdk-versions)
[![Auto-committer](https://img.shields.io/github/workflow/status/isen-ng/homebrew-dotnet-sdk-versions/auto-committer?label=auto-committer)](https://github.com/isen-ng/homebrew-dotnet-sdk-versions/actions?query=workflow%3Aauto-committer)

This tap contains different versions that you can install in parallel to the latest version provided by the [official
cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/dotnet-sdk.rb).

Install one of the previous versions by tapping this repository and running the install command.

## Installing one of the versions here

```
brew tap isen-ng/dotnet-sdk-versions
brew cask install <version>

dotnet --list-sdks
```

### Versions

| Version              | DotNet SDK     | Remarks
|----------------------|----------------|-----------
| `dotnet-sdk-3.1.300` | dotnet 3.1.302 | Conflicts with official cask if `OS > sierra`. Latest LTS
| `dotnet-sdk-3.1.200` | dotnet 3.1.202 |
| `dotnet-sdk-3.1.100` | dotnet 3.1.107 |
| `dotnet-sdk-3.0.100` | dotnet 3.0.103 |
| `dotnet-sdk-2.2.400` | dotnet 2.2.402 | Conflicts with official cask if `OS == sierra`
| `dotnet-sdk-2.2.300` | dotnet 2.2.301 |
| `dotnet-sdk-2.2.200` | dotnet 2.2.207 |
| `dotnet-sdk-2.2.100` | dotnet 2.2.110 |
| `dotnet-sdk-2.1.800` | dotnet 2.1.809 |
| `dotnet-sdk-2.1.500` | dotnet 2.1.517 |
| `dotnet-sdk-2.1.400` | dotnet 2.1.403 |

## Uninstalling

Because the dotnet packages uses shared dependencies between different versions, it is unwise to delete these 
dependencies when uninstalling a particular version as it will cause other versions not to work. 

If there is a need to purge these dependencies, use the `zap` command:

```
brew cask zap <version>
```

*Important*: Uninstalling the offical version will also remove these dependencies, so you'll need to reinstall the particular version you want to use again.

## Using a particular version

The `dotnet` command will automatically use the latest appropriate version unless specified by
[global.json](https://docs.microsoft.com/en-us/dotnet/core/tools/global-json).
