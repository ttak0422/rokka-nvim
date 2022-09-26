# rokka-nvim 

> "六花 (rokka)" is another name for snow in Japanese.

## About.

Rokka adds a thin configuration layer of the NeoVim plugins to [home-manager](https://github.com/nix-community/home-manager)'s configuration.
It provides both usability and performance by implementing the settings and optimizations on the Nix side and working with Lua, 

## Options.

### rokka option

| name | type | default | description |
|:-:|:-:|:-:|:-:|
| enable | bool | true | enable `rokka-nvim`. |
| plugins | listOf (`pluginUserConfigType` \| package) | [] | vim plugins. |
| extraPackages | listOf package | [] | nix package. |
| delayTime | int (milliseconds) | 100 | use for delay loader. |
| logLevel | enum | "warn" | log level ("debug" \| "info" \| "warn" \| "error"). |
| withNodeJs | bool | false | alias for nvim.withNodeJs |
| withPython3 | bool | false | alias for nvim.withPython3 |
| withRuby | bool | false | alias for nvim.withRuby |

### rokka plugin option (`pluginUserConfigType`)

| name | type | default | description |
|:-:|:-:|:-:|:-:|
| plugin | package | - | vim plugin. |
| enable | bool | true | enable plugin. |
| optional | bool | true | true -> `opt`, false -> `start`. |
| startup | nullOr str | null | - |
| config | nullOr str | null | - |
| depends | listOf (`pluginUserConfigType` \| package) | [] | - |
| dependsAfter | listOf (`pluginUserConfigType` \| package) | [] | - |
| events | listOf str | [] | - |
| commands | listOf str | [] | - |
| fileTypes | listOf str | [] | - |
| delay | bool | false | delay flag. |
| optimize | bool | true | optimize flag. |
| extraPackages | listOf package | [] | nix package. |

## Example.

```nix
programs.neovim = {
  enable = true;
  package = pkgs.neovim-nightly;
};
programs.rokka-nvim = {
  enable = true;
  logLevel = "debug";
  plugins = with pkgs.vimPlugins; [
    ale
    {
      plugin = nvim-cmp;
      depends = [ cmp-path ];
      startup = "";
      config = ''
        -- WIP: rokka-nvim does support `after`. You need to call `after` explicitly.
        vim.cmd[[silent source ${cmp-path}/after/plugin/cmp_path.lua]]

        vim.opt.completeopt = "menu,menuone,noselect"
        local cmp = require'cmp'
        cmp.setup {
          sources = {
            { name = 'path' }
          }
        }
      '';
      events = [ "InsertEnter" ];
    }
    {
      plugin = vim-sensible;
      optional = false;
    }
    {
      plugin = ayu-vim;
      startup = ''
        vim.cmd([[set termguicolors]])
        vim.cmd([[let ayucolor="light"]])
        vim.cmd([[colorscheme ayu]])
      '';
    }
    {
      plugin = telescope-nvim;
      depends = [ plenary-nvim ];
      commands = [ "Telescope" ];
    }
    {
      plugin = diffview-nvim;
      depends = [ { plugin = plenary-nvim; } ];
      commands = [ "DiffviewOpen" ];
    }
    {
      plugin = hop-nvim;
      events = [ "InsertEnter" ];
      config = ''
        require'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
      '';
    }
    {
      plugin = neoscroll-nvim;
      delay = true;
    }
    {
      plugin = vim-nix;
      fileTypes = [ "nix" ];
    }
    {
      plugin = glow-nvim;
      commands = [ "Glow" ];
      extraPackages = [ pkgs.glow ];
    }
  ];
};
```

## Test.

```bash
nixt ./tests/ -v
```

<img alt="nix" src="https://builtwithnix.org/badge.svg">
