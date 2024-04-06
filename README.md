# nvim-sluice

A neovim minimap of the +signs gutter for the right side of the window.

## Install

You can install this plugin using a variety of plugin managers.

Plug:

```
Plug 'dsummersl/nvim-sluice'
```

Lazy:

```
{
  "dsummersl/nvim-sluice",
  config = function()
    require("sluice").setup({
      ... override any defaults ...
    })
  end
},

```


Default configuration:

```vim
{
  enable = true,
  gutters = { {
      plugins = { "viewport", "search" },
      window = {
        default_gutter_hl = "SluiceColumn",
        enabled_fn = <function 1>,
        width = 1
      }
    }, {
      plugins = { "viewport", "signs" },
      window = {
        count_method = "",
        default_gutter_hl = "SluiceColumn",
        enabled_fn = <function 2>,
        width = 1
      }
    } },
  throttle_ms = 150
}
```

## Configuration

You can configure nvim-sluice to create custom gutters on either the left or the right side of the screen. Each gutter can be configured to display specific symbols and have a custom width. You can also specify which groups to include or exclude from the gutter.

Example configuration with left and right gutters:

```vim
{
  enable = true,
  gutters = {
    left = { -- Define a gutter on the left side
      plugins = { "gitsigns", "lsp" },
      window = {
        default_gutter_hl = "SluiceGutter",
        enabled_fn = <function 1>,
        width = 2,
        whitelist = { "GitSignsAdd", "GitSignsChange", "LspDiagnosticsSignError" },
        blacklist = { "GitSignsDelete" }
      }
    },
    right = { -- Define a gutter on the right side (existing functionality)
      plugins = { "viewport", "search" },
      window = {
        default_gutter_hl = "SluiceColumn",
        enabled_fn = <function 2>,
        width = 1
      }
    }
  },
  throttle_ms = 150
}
```

In the above example, the left gutter is configured to show signs from gitsigns and LSP messages, with a width of 2 cells. It includes only the specified whitelist groups and excludes the blacklist groups. The right gutter remains as previously configured.

## Screenshot

[![asciicast](./static/screenshot.png)](https://asciinema.org/a/QXQfhGBm5Zlx1R2oYQkgQfYVu?t=10)

See this [asciinema screencast](https://asciinema.org/a/QXQfhGBm5Zlx1R2oYQkgQfYVu?t=10) for a demonstration.

## Commands

`SluiceEnable`/`SluiceDisable`/`SluiceToggle`.

## Development

Install dependencies:

    luarocks --lua-version 5.1 install busted
    luarocks --lua-version 5.1 install luacheck

Run tests:

    make lint
    make test

## Notes

Thanks to [nvim-treesitter-context](https://github.com/romgrk/nvim-treesitter-context) which I based the lua windowing that this plugin uses.

The idea behind this project is based on [vim-sluice](https://github.com/dsummersl/vim-sluice) -- a buggier and more feature-ful version of this plugin for vim/gvim.

## Features

With the new configuration options, you can:

- Define gutters on both the left and right sides of the screen.
- Configure the symbols and width of each gutter.
- Whitelist or blacklist specific highlight groups to fine-tune what is displayed in the gutters.
- Create dedicated gutters for specific plugins like gitsigns or LSP messages.

These features provide greater flexibility in how you view and interact with different signs and messages within Neovim.

- https://github.com/lewis6991/satellite.nvim -- a good inspiration for a reboot from 
