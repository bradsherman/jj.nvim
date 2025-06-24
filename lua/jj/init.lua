local M = {}
local cmd = require("jj.cmd")

M.picker_config = {
	snacks = {
		layout = "horizontal",
	},
}

--- Jujutsu plugin configuration
--- @class jj.Config
M.config = {
	-- Default configuration
}

--- Setup the plugin
--- @param opts jj.Config: Options to configure the plugin
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	cmd.register_command()
end

return M
