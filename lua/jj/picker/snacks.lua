local utils = require("jj.utils")

--- @class jj.picker.snacks
local M = {}

--- Displays the status files in a snacks picker
---@param opts  jj.picker.config
---@param files jj.picker.file[]
function M.status(opts, files)
	if not opts.snacks then
		return utils.notify("Snacks picker is `disabled`", vim.log.levels.INFO)
	end

	local snacks = require("snacks")

	local snacks_opts
	-- If its true we default to an empty table
	if opts.snacks == true then
		snacks_opts = {}
	else
		--- Otherwise we get the table from the config
		---@type table
		snacks_opts = opts.snacks
	end

	local merged_opts = vim.tbl_deep_extend("force", snacks_opts, {
		source = "jj",
		items = files,
		title = "JJ Status",
		preview = function(ctx)
			if ctx.item.file then
				snacks.picker.preview.cmd(ctx.item.diff_cmd, ctx, {})
			end
		end,
	})

	snacks.picker.pick(merged_opts)
end

return M
