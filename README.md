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

## TODO

- Show specific highlights visible in the screen (matchup in particular)
- Show the current visual select.
- Add options to the signs plugin to whitelist or blacklist specific patterns

- https://github.com/lewis6991/satellite.nvim -- a good inspiration for a reboot from 
