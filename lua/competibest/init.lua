local config = require("competibest.config")
local M = {}

---Setup competibest
---@param opts table | nil: a table containing user configuration
function M.setup(opts)
	config.current_setup = config.update_config_table(config.current_setup, opts)

	if not config.current_setup.loaded then
		config.current_setup.loaded = true

		-- competibest command
		vim.cmd([[
		function! s:command_completion(_, CmdLine, CursorPos) abort
			let prefix = a:CmdLine[:a:CursorPos]
			let ending_space = prefix[-1:-1] == " "
			let words = split(prefix)
			let wlen = len(words)

			if wlen == 1 || wlen == 2 && !ending_space
				return "add_testcase\nedit_testcase\ndelete_testcase\nconvert\nrun\nrun_no_compile\nshow_ui\nreceive"
			elseif wlen == 2 || wlen == 3 && !ending_space
				if wlen == 2
					let lastword = words[-1]
				else
					let lastword = words[-2]
				endif

				if lastword == "convert"
					return "auto\nfiles_to_singlefile\nsinglefile_to_files"
				endif
			endif
			return ""
		endfunction
		command! -bar -nargs=* -complete=custom,s:command_completion Competibest lua require("competibest.commands").command(<q-args>)
		]])

		-- create highlight groups
		M.setup_highlight_groups()
		vim.api.nvim_command("autocmd ColorScheme * lua require('competibest').setup_highlight_groups()")

		-- resize ui autocommand
		vim.api.nvim_command("autocmd VimResized * lua require('competibest').resize_ui()")

		vim.cmd([[Competibest receive]])
	end
end

---Resize competibest user interface if visible
function M.resize_ui()
	vim.schedule(function()
		require("competibest.widgets").resize_widgets()
		for _, r in pairs(require("competibest.commands").runners) do
			r:resize_ui()
		end
	end)
end

---Create competibest highlight groups
function M.setup_highlight_groups()
	local highlight_groups = {
		{ "competibestRunning", "cterm=bold gui=bold" },
		{ "competibestDone", "cterm=none gui=none" },
		{ "competibestCorrect", "ctermfg=green guifg=#00ff00" },
		{ "competibestWarning", "ctermfg=yellow guifg=orange" },
		{ "competibestWrong", "ctermfg=red guifg=#ff0000" },
	}
	for _, hl in ipairs(highlight_groups) do
		vim.api.nvim_command("hi! def " .. hl[1] .. " " .. hl[2])
	end
end

return M
