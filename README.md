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
brew install --cask <version>

dotnet --list-sdks
```

### Versions

| Version             | DotNet SDK     | Arch        | Remarks
|---------------------|----------------|-------------|---------
| `dotnet-sdk6-0-400` | dotnet 6.0.401 | x64 & arm64 |
| `dotnet-sdk6-0-300` | dotnet 6.0.303 | x64 & arm64 |
| `dotnet-sdk6-0-200` | dotnet 6.0.202 | x64 & arm64 |
| `dotnet-sdk6-0-100` | dotnet 6.0.108 | x64 & arm64 |
| `dotnet-sdk5-0-400` | dotnet 5.0.408 | x64         | When installed on arm64, use `dotnetx64`
| `dotnet-sdk5-0-200` | dotnet 5.0.209 | x64         | When installed on arm64, use `dotnetx64`
| `dotnet-sdk3-1-400` | dotnet 3.1.424 | x64         | When installed on arm64, use `dotnetx64`
| `dotnet-sdk3-1-300` | dotnet 3.1.302 | x64         |
| `dotnet-sdk3-1-200` | dotnet 3.1.202 | x64         |
| `dotnet-sdk3-1-100` | dotnet 3.1.120 | x64         |
| `dotnet-sdk3-0-100` | dotnet 3.0.103 | x64         |
| `dotnet-sdk2-2-400` | dotnet 2.2.402 | x64         | 
| `dotnet-sdk2-2-300` | dotnet 2.2.301 | x64         |
| `dotnet-sdk2-2-200` | dotnet 2.2.207 | x64         |
| `dotnet-sdk2-2-100` | dotnet 2.2.110 | x64         |
| `dotnet-sdk2-1-800` | dotnet 2.1.818 | x64         |
| `dotnet-sdk2-1-500` | dotnet 2.1.526 | x64         |
| `dotnet-sdk2-1-400` | dotnet 2.1.403 | x64         |

**Note**: Installing dotnet sdk 5 using this tap or the official pkg from Microsoft will uninstall all other 
dotnet sdks on your machine. To overcome this you'll need to re-install the sdk versions you want from this tap 
after installing/upgrading to dotnet sdk 5.


### Preview versions

| Version               | DotNet SDK                       | Arch        | Remarks
|-----------------------|----------------------------------|-------------|---------
| `dotnet-sdk7-preview` | dotnet 7.0.100-preview.7.22377.5 | x64 & arm64 |

**Note**: Preview versions is a newly supported feature (as of September 2022). Please send feedback/create issues
if there are problems with the compatibility of the preview versions.


## Uninstalling

Because the dotnet packages uses shared dependencies between different versions, it is unwise to delete these 
dependencies when uninstalling a particular version as it will cause other versions not to work. 

If there is a need to purge these dependencies, use the `zap` flag:

```
brew uninstall --zap --cask <version>
```

*Important*: Uninstalling the offical version will also remove these dependencies, so you'll need to reinstall the particular version you want to use again.

## Using a particular version

The `dotnet` command will automatically use the latest appropriate version unless specified by
[global.json](https://docs.microsoft.com/en-us/dotnet/core/tools/global-json).
