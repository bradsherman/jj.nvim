local M = {}
local cmd = require("jj.cmd")
local picker = require("jj.picker")

--- Jujutsu plugin configuration
--- @class jj.Config
M.config = {
	-- Default configuration
	--- @type jj.picker.config
	picker = {
		snacks = {},
	},
}

--- Setup the plugin
--- @param opts jj.Config: Options to configure the plugin
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	picker.setup(opts.picker)

	cmd.register_command()
end

return M
