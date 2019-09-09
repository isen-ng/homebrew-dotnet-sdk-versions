# dotnet-sdk versions tap

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
| DotNet Version | SDK                  | Is latest
|----------------|----------------------|------------
| dotnet 2.2.401 | `dotnet-sdk-2.2.401` | Yes
| dotnet 2.2.301 | `dotnet-sdk-2.2.301` |
| dotnet 2.2.300 | `dotnet-sdk-2.2.300` |
| dotnet 2.2.107 | `dotnet-sdk-2.2.107` |

*Note*: Latest version conflicts with the official version

## Uninstalling

Because the dotnet packages uses shared dependencies between different versions, it is unwise to delete these 
dependencies when uninstalling a particular version as it will cause other versions not to work. 

If there is a need to purge these dependencies, use the `zap` command:

```
brew cask zap <version>
```

*Important*: Uninstalling the offical version will also remove these dependencies, so you'll need to reinstall the particular version you want to use again.