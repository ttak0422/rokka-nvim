# [WIP] rokka-nvim

> "六花 (rokka)" is another name for snow in Japanese.

## Options.

### rokka option

| name | type | default | description |
|:-:|:-:|:-:|:-:|
| enable | bool | true | enable `rokka-nvim`. |
| plugins | listOf `pluginUserConfigType` | [] | vim plugins. |
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
| delay | bool | false | delay flag. |
| optimize | bool | true | optimize flag. |
| extraPackages | listOf package | [] | nix package. |

## Example.

```nix
programs.rokka-nvim = {
  enable = true;
  logLevel = "debug";
  plugins = [
    {
      plugin = pkgs.vimPlugins.vim-sensible;
      optional = false;
    }
    {
      plugin = pkgs.vimPlugins.ayu-vim;
      startup = ''
        vim.cmd([[set termguicolors]])
        vim.cmd([[let ayucolor="light"]])
        vim.cmd([[colorscheme ayu]])
      '';
    }
    {
      plugin = pkgs.vimPlugins.telescope-nvim;
      depends = with pkgs.vimPlugins; [ plenary-nvim ];
      commands = [ "Telescope" ];
    }
    {
      plugin = pkgs.vimPlugins.hop-nvim;
      events = [ "InsertEnter" ];
      config = ''
        require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
      '';
    }
    {
      plugin = pkgs.vimPlugins.neoscroll-nvim;
      delay = true;
    }
    {
      plugin = pkgs.vimPlugins.vim-nix;
      fileTypes = [ "nix" ];
    }
    {
      plugin = pkgs.vimPlugins.glow-nvim;
      commands = [ "Glow" ];
      extraPackages = [ pkgs.glow ];
    };
  ];
};
```