# jj.nvim

⚠️ **VERY WORK IN PROGRESS - NOT READY FOR MASSIVE USE** ⚠️

A Neovim plugin for [Jujutsu (jj)](https://github.com/jj-vcs/jj) version control system.

## About

This plugin aims to be something like vim-fugitive but for piloting the jj-vcs CLI. The goal is to eventually provide features similar to git status, diffs, and pickers for managing Jujutsu repositories directly from Neovim.

## Current Features

- Basic jj command execution through `:J` command
- Terminal-based output display for jj commands
- Support for common jj subcommands:
  - `describe` - Set change descriptions
  - `status` / `st` - Show repository status
  - `log` - Display log history with configurable options
  - `diff` - Show changes
  - `new` - Create a new change
  - `edit` - Edit a change
  - `squash` - Squash the current diff to it's parent

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "nicolasgb/jj.nvim",
  config = function()
    require("jj").setup({})
  end,
}
```

## Usage

The plugin provides a `:J` command that accepts jj subcommands:

```vim
:J status
:J log
:J describe "Your change description"
:J new
```

## Requirements

- Neovim >= 0.9.0
- [Jujutsu](https://github.com/jj-vcs/jj) installed and available in PATH

## Contributing

This is an early-stage project. Contributions are welcome, but please be aware that the API and features are likely to change significantly.

## License

[MIT](License)
