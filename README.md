# jj.nvim

⚠️ **WORK IN PROGRESS** ⚠️

A Neovim plugin for [Jujutsu (jj)](https://github.com/jj-vcs/jj) version control system.

## About

This plugin aims to be something like vim-fugitive but for piloting the jj-vcs CLI. The goal is to eventually provide features similar to git status, diffs, and pickers for managing Jujutsu repositories directly from Neovim.

## Current Features

- Basic jj command execution through `:J` command
- Terminal-based output display for jj commands
- Support jj subcommands including your aliases through the cmdline.
- Native lua calls for the following jj subcommands:
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

## Cmdline Usage

The plugin provides a `:J` command that accepts jj subcommands:

```sh
:J status
:J log
:J describe "Your change description"
:J new
:J # This will use your defined default command
:J <your-alias>
```

## Example config

```lua
{
  "nicolasgb/jj.nvim",
  config = function()
    require("jj").setup({})
    local cmd = require "jj.cmd"
    vim.keymap.set("n", "<leader>jd", cmd.describe, { desc = "JJ describe" })
    vim.keymap.set("n", "<leader>jl", cmd.log, { desc = "JJ log" })
    vim.keymap.set("n", "<leader>je", cmd.edit, { desc = "JJ edit" })
    vim.keymap.set("n", "<leader>jn", cmd.new, { desc = "JJ new" })
    vim.keymap.set("n", "<leader>js", cmd.status, { desc = "JJ status" })
    vim.keymap.set("n", "<leader>dj", cmd.diff, { desc = "JJ diff" })
    vim.keymap.set("n", "<leader>sj", cmd.squash, { desc = "JJ squash" })

    -- Some functions like `describe` or `log` can take parameters
    vim.keymap.set("n", "<leader>jl", function()
      cmd.log {
        revisions = "all()",
      }
    end, { desc = "JJ log" })

  end,
}

```

## Requirements

- [Jujutsu](https://github.com/jj-vcs/jj) installed and available in PATH

## Contributing

This is an early-stage project. Contributions are welcome, but please be aware that the API and features are likely to change significantly.

## License

[MIT](License)
