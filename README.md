# [WIP] rokka-nvim

> "六花 (rokka)" is another name for snow in Japanese.

## Options.

### rokka option

| name | type | default | description |
|:-:|:-:|:-:|:-:|
| enable | bool | true | enable `rokka-nvim`. |
| plugins | `pluginUserConfigType` | [] | vim plugins. |
| extraPackages | listOf package | [] | nix package. |
| delayTime | int (milliseconds) | 100 | use for delay loader. |
| logLevel | enum | "warn" | log level ("trace" \| "debug" \| "info" \| "warn" \| "error" \| "fatal"). |

### rokka plugin option (`pluginUserConfigType`)

| name | type | default | description |
|:-:|:-:|:-:|:-:|
| plugin | package | - | vim plugin. |
| enable | bool | true | enable plugin. |
| optional | bool | true | true -> `opt`, false -> `start`. |
| startup | nullOr str | null | - |
| config | nullOr str | null | - |
| depends | :construction: listOf package | [] | - |
| rtp | nullOr str | null | subdirectory. |
| as | nullOr str | null | use different name for plugin. |
| events | listOf str | [] | - |
| commands | listOf str | [] | - |
| fileTypes | listOf str | [] | - |
| delay | bool | false | [] | - |
| optimize | bool | true | optimize flag. |
| extraPackages | listOf package | [] | nix package. |