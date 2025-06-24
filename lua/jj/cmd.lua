--- @class jj.cmd
local M = {}

local utils = require("jj.utils")

local state = {
	-- The current terminal buffer for jj commands
	--- @type integer|nil
	terminal_buf = nil,
	-- The current channel to communciate with the terminal
	--- @type integer|nil
	chan = nil,
	--- The current job id for the terminal buffer
	--- @type integer|nil
	job_id = nil,
}

--- Close the current terminal buffer if it exists
local function close_terminal_buffer()
	if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
		vim.cmd("bwipeout! " .. state.terminal_buf)
	else
		vim.cmd("close")
	end
end

--- Execute jj describe command with the given description
---@param description string The description text
local function execute_describe(description)
	if not description or description == "" then
		utils.notify("Description cannot be empty", vim.log.levels.ERROR)
		return
	end

	local cmd = string.format("jj describe -m '%s'", description)
	local _, success = utils.execute_command(cmd, "Failed to describe")
	if not success then
		return
	else
		utils.notify("Description set.", vim.log.levels.INFO)
	end
end

--- @class jj.cmd.describe_opts
--- @field with_status boolean: Whether or not `jj st` should be displayed in a buffer while describing the commit

--- @type jj.cmd.describe_opts
local default_describe_opts = {
	with_status = true,
}

--- Jujutsu describe
---@param description? string Optional description text
---@param opts? jj.cmd.describe_opts Optional command options
function M.describe(description, opts)
	if not utils.ensure_jj() then
		return
	end

	-- Check if a description was provided otherwise require for input
	if not description then
		local merged_opts = vim.tbl_deep_extend("force", default_describe_opts, opts or {})
		if merged_opts.with_status then
			-- Show the status in a terminal buffer
			M.status()
		end

		vim.ui.input({
			prompt = "Description: ",
			default = "",
		}, function(input)
			-- If the user inputed something, execute the describe command
			if input then
				execute_describe(input)
			end
			-- Close the current terminal when finished
			close_terminal_buffer()
		end)
	end
end

--- Jujutsu status
function M.status()
	if not utils.ensure_jj() then
		return
	end

	local cmd = "jj st"
	M.show_output_in_terminal(cmd)
end

--- Jujutsu new
function M.new()
	if not utils.ensure_jj() then
		return
	end

	local cmd = "jj new"
	utils.execute_command(cmd, "Failed to create new")
	utils.notify("Command `new` was succesful.", vim.log.levels.INFO)
end

-- Jujutsu edit
function M.edit()
	if not utils.ensure_jj() then
		return
	end
	M.log({})
	vim.ui.input({
		prompt = "Change to edit: ",
		default = "",
	}, function(input)
		-- If the user inputed something, execute the describe command
		if input then
			local _, success = utils.execute_command(string.format("jj edit %s", input), "Error editing change")
			if not success then
				return
			end

			-- If ok update the log window
			M.log({})
		else
			-- If user exited without saving discard the log
			close_terminal_buffer()
		end
	end)
end

--- Jujutsu squash
function M.squash()
	if not utils.ensure_jj() then
		return
	end

	local cmd = "jj squash"
	local _, success = utils.execute_command(cmd, "Failed to squash")
	if success then
		utils.notify("Command `squash` was succesful.", vim.log.levels.INFO)
	end
end

---@class jj.cmd.log_opts
---@field summary? boolean: Show a summary of the log
---@field reversed? boolean: Show the log in reverse order
---@field no_graph? boolean: Do not show the graph in the log output
---@field limit? uinteger : Limit the number of log entries shown, defaults to 20 if not provided
---@field revisions? string: Which revisions to show

--- @type jj.cmd.log_opts
local default_log_opts = {
	--- @type boolean
	summary = false,
	--- @type boolean
	reversed = false,
	--- @type boolean
	no_graph = false,
	--- @type uinteger
	limit = 20,
}
--- Jujutsu log
---@param opts jj.cmd.log_opts Command options from nvim_create_user_command
function M.log(opts)
	if not utils.ensure_jj() then
		return
	end

	local cmd = "jj log"

	-- Merge default options with provided ones
	local merged_opts = vim.tbl_extend("force", default_log_opts, opts or {})

	-- Add options to the command
	for key, value in pairs(merged_opts) do
		-- Replace _ with - for command line options
		key = key:gsub("_", "-")

		-- Handle special cases such as limit
		if key == "limit" and value then
			cmd = string.format("%s --%s %d", cmd, key, value)
		elseif key == "revisions" and value then
			cmd = string.format("%s --%s %s", cmd, key, value)
		elseif value then
			-- Simply append the option
			cmd = string.format("%s --%s", cmd, key)
		end
	end

	M.show_output_in_terminal(cmd)
end

--- Jujutsu diff
function M.diff()
	if not utils.ensure_jj() then
		return
	end

	local cmd = "jj diff"
	M.show_output_in_terminal(cmd)
end

--- Run a command and show it's output in a terminal buffer
---@param cmd string
function M.show_output_in_terminal(cmd)
	if state.terminal_buf and state.chan then
		-- If we already have a terminal buffer, just switch to it
		vim.api.nvim_set_current_buf(state.terminal_buf)
		-- Send ansi escape sequence to clear the terminal
		vim.api.nvim_chan_send(state.chan, "\27[H\27[2J")
	else
		-- Split window and create buffer
		vim.cmd("split")
		-- Otherwise, create a new terminal buffer and store it in the state
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_create_buf(false, true)

		state.terminal_buf = buf
		vim.api.nvim_win_set_buf(win, buf)
	end

	-- If there was a previous channel with a terminal close it
	if state.chan then
		vim.fn.chanclose(state.chan)
	end
	-- If there was a previous job stop it
	if state.job_id then
		vim.fn.jobstop(state.job_id)
	end

	-- For sure it's set to a terminal buffer
	--- @type integer
	local buf = state.terminal_buf
	local win = vim.api.nvim_get_current_win()

	-- Set buffer options
	vim.bo[buf].bufhidden = "wipe"

	-- Create a terminal job that runs the command and exits
	--- @type integer
	local chan = vim.api.nvim_open_term(buf, {})
	if not chan or chan <= 0 then
		vim.notify("Failed to create terminal channel", vim.log.levels.ERROR)
		return
	end

	-- Set it in the state to close it later
	state.chan = chan

	local jid = vim.fn.jobstart(cmd, {
		pty = true,
		width = vim.api.nvim_win_get_width(win),
		height = vim.api.nvim_win_get_height(win),
		env = {
			TERM = "xterm-256color",
			PAGER = "cat",
			DELTA_PAGER = "cat",
			COLORTERM = "truecolor",
		},
		on_stdout = function(_, data)
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			-- Send output directly to the terminal
			local ouptut = table.concat(data, "\n")
			vim.api.nvim_chan_send(chan, ouptut)
		end,
		on_exit = function(_, _)
			if vim.api.nvim_buf_is_valid(buf) then
				-- Once the job exits, we can set the buffer to be non-modifiable
				vim.bo[buf].modifiable = false

				-- Switch to normal mode after command completes
				vim.schedule(function()
					if vim.api.nvim_get_current_buf() == buf then
						vim.cmd("stopinsert")
					end
				end)
			end
		end,
	})

	-- TODO: HANDLE ERRORS BETTER
	if jid <= 0 then
		vim.api.nvim_chan_send(chan, "Failed to start command: " .. cmd .. "\r\n")
	else
		-- Store the job ID in the state for later reference
		state.job_id = jid
	end

	-- Set keymaps to close and wipe buffer

	-- Avoid the user being able to go in insert mode for this buffer
	vim.keymap.set("n", "i", function() end, { buffer = buf, noremap = true, silent = true })

	-- Set keymaps for closing the terminal buffer
	vim.keymap.set("n", "q", close_terminal_buffer, { buffer = buf, noremap = true, silent = true })
	vim.keymap.set("n", "<ESC>", close_terminal_buffer, { buffer = buf, noremap = true, silent = true })

	-- Start in normal mode
	vim.cmd("stopinsert")

	--- Watch for buffer close events to clean up terminal buffer from the state
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		buffer = buf,
		callback = function(_)
			-- Clear the terminal buffer
			if state.terminal_buf and vim.api.nvim_buf_is_valid(state.terminal_buf) then
				state.terminal_buf = nil
			end

			--- Clear the channel
			if state.chan then
				vim.fn.chanclose(state.chan)
			end

			-- Clear the job since the terminal is closed
			if state.job_id then
				vim.fn.jobstop(state.job_id)
				state.job_id = nil
			end
		end,
	})
end

--- Handle J command with subcommands and direct jj passthrough
---@param opts table Command options from nvim_create_user_command
function M.handle_j_command(opts)
	if not utils.ensure_jj() then
		return
	end

	local args = opts.fargs
	if #args == 0 then
		-- Use the user's default command and do not try to parse anythng else
		M.show_output_in_terminal("jj")
		return
	end

	local subcommand = args[1]
	local remaining_args = vim.list_slice(args, 2)

	local cmd_args = table.concat(args, " ")
	local cmd = string.format("jj %s", cmd_args)

	-- Handle known subcommands with custom logic
	if subcommand == "describe" then
		local description = table.concat(remaining_args, " ")
		M.describe(description ~= "" and description or nil)
		return
	elseif subcommand == "edit" then
		M.edit()
		return
	elseif subcommand == "new" then
		local _, success = utils.execute_command(cmd, "Failed to edit change")
		if not success then
			return
		end

		M.log({})
	end

	-- Run the command in the terminal
	M.show_output_in_terminal(cmd)
end

--- Register the J command
function M.register_command()
	vim.api.nvim_create_user_command("J", M.handle_j_command, {
		nargs = "*",
		complete = function(arglead, _, _)
			-- Basic completion for common jj subcommands
			local subcommands = {
				"log",
				"status",
				"st",
				"diff",
				"describe",
				"new",
				"squash",
				"bookmark",
				"edit",
				"abandon",
				"b",
				"git",
			}

			local matches = {}
			for _, cmd in ipairs(subcommands) do
				if cmd:match("^" .. vim.pesc(arglead)) then
					table.insert(matches, cmd)
				end
			end
			return matches
		end,
		desc = "Execute jj commands with subcommand support",
	})
end

return M
