# themer.nvim - A Simple Theme Selector for Neovim

A very basic theme selector popup for Neovim. Made this for my personal use, so use at your own risk!

⚠️ **Warning**: This is a work in progress and might break your Neovim setup. I only made this for myself and decided to share it. Expect bugs!

## Installation

### Lazy.nvim
```lua
{
    'DecisiveOpinion/themer.nvim',
    config = function()
        require('themer').setup({
            themes = {
                { name = "Gruvbox", colorscheme = "gruvbox" },
                { name = "Tokyo Night", colorscheme = "tokyonight" },
                -- Add whatever themes you want here
            }
        })
    end
}
```

### Packer.nvim
```lua
use {
    'DecisiveOpinion/themer.nvim',
    config = function()
        require('themer').setup({
            themes = {
                { name = "Gruvbox", colorscheme = "gruvbox" },
                { name = "Tokyo Night", colorscheme = "tokyonight" },
            }
        })
    end
}
```

## Usage

After installing, use `:ThemeSelect` to open the theme selector popup. You can:
- Search themes by typing
- Use arrow keys to navigate
- Press Enter to select a theme
- Press Esc to cancel

The selected theme will be saved and loaded next time you start Neovim.

## Configuration

```lua
require('themer').setup({
    -- Required: List of your themes
    themes = {
        { name = "Display Name", colorscheme = "actual_theme_command" },
    },

    -- Optional settings
    width = 60,        -- Width of popup
    height = 20,       -- Height of popup
    border = "rounded", -- Border style
    checkmark = "✓"    -- Symbol for selected theme
})
```

## Why?

I got tired of changing themes by typing `:colorscheme whatever`. I tried [Themery](https://github.com/zaldih/themery.nvim) and liked it but wanted a search bar. Also needed something to practice making Neovim plugins with.

## Known Issues

- Sometimes when searching it doesn't switch the theme preview to the top of the list.
- When opening the switcher, the cursor always goes to the top, rather than the selected theme.
- Probably other issues I haven't found yet.

Feel free to fix things if you want, but remember this is mainly for personal use!

## License

Do whatever you want with it! (MIT)
