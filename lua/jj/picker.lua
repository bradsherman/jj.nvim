local utils = require("jj.utils")

--- @class jj.picker

--- @class jj.picker.config
--- @field snacks table|boolean The snacks config

--- @class jj.picker.file
--- @field file string The path of the file
--- @field change string The type of change in the file
--- @field diff_cmd string The command to get the diff of the file

local M = {
	--- @type jj.picker.config
	config = {
		snacks = {},
	},
}

--- Initializes the picker
--- @param opts jj.picker.config
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Gets the files in the current jj repository
--- @return jj.picker.file[]|nil A list of files with their changes or nil if not in a jj repo
local function get_files()
	local diff_ouptut, ok = utils.execute_command("jj diff --summary --quiet")
	if not ok then
		return
	end

	if type(diff_ouptut) ~= "string" then
		return utils.notify("Could not get diff output", vim.log.levels.ERROR)
	end

	local files = {}

	-- Split the output into lines
	local lines = vim.split(diff_ouptut, "\n", { trimempty = true })

	for _, line in ipairs(lines) do
		local change, file_path = line:match("^(%a)%s(.+)$")

		table.insert(files, {
			text = file_path,
			file = file_path,
			change = change,
			diff_cmd = string.format("jj diff %s", file_path),
		})
	end

	return files
end

--- Displays in the configurated picker the status of the files
function M.status()
	-- Ensure jj is installed
	if not utils.ensure_jj() then
		return
	end

	local files = get_files()
	if not files or #files == 0 then
		return utils.notify("`Picker`: No diffs found", vim.log.levels.INFO)
	end

	if M.config.snacks then
		require("jj.picker.snacks").status(M.config, files)
	else
		return utils.notify("No `Picker` enabled", vim.log.levels.INFO)
	end
end

return M
