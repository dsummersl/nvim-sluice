# nvim-sluice

A signs 'macro view' gutter for the right side of the window.

## Install

```vim
Plug 'dsummersl/nvim-sluice'
```

## Screenshot

[![asciicast](https://asciinema.org/a/EVPJgGpjO0KEVsLiR2p56u1IJ.svg)](https://asciinema.org/a/EVPJgGpjO0KEVsLiR2p56u1IJ)


## Commands

`SluiceEnable` and `SluiceDisable`.

## Development

Install dependencies:

    luarocks install busted

Run tests:

    make lint
    make test

## Notes

Thanks to [nvim-treesitter-context](https://github.com/romgrk/nvim-treesitter-context) which I based the lua windowing that this plugin uses.

The idea behind this project is based on [vim-sluice](https://github.com/dsummersl/vim-sluice) -- a buggier and more feature-ful version of this plugin for vim/gvim.
