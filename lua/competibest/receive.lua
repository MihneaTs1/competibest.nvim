local luv = vim.loop
local testcases = require("competibest.testcases")
local utils = require("competibest.utils")
local M = {}

---Convert a string with competibest receive modifiers into a formatted string
---@param str string: the string to evaluate
---@param task table: table with received task data
---@param file_extension string
---@param remove_illegal_characters boolean: whether to remove windows illegal characters from modifiers or not
---@param date_format string | nil: string used to format date
---@return string | nil: the converted string, or nil on failure
function M.eval_receive_modifiers(str, task, file_extension, remove_illegal_characters, date_format)
	local judge, contest
	local hyphen = string.find(task.group, " - ", 1, true)
	if not hyphen then
		judge = task.group
		contest = "unknown_contest"
	else
		judge = string.sub(task.group, 1, hyphen - 1)
		contest = string.sub(task.group, hyphen + 3)
	end

	local receive_modifiers = {
		[""] = "$", -- $(): replace it with a dollar
		["HOME"] = luv.os_homedir(), -- home directory
		["CWD"] = vim.fn.getcwd(), -- current working directory
		["FEXT"] = file_extension,
		["PROBLEM"] = task.name, -- problem name, name field
		["GROUP"] = task.group, -- judge and contest name, group field
		["JUDGE"] = judge, -- first part of group, before hyphen
		["CONTEST"] = contest, -- second part of group, after hyphen
		["URL"] = task.url, -- problem url, url field
		["MEMLIM"] = tostring(task.memoryLimit), -- available memory, memoryLimit field
		["TIMELIM"] = tostring(task.timeLimit), -- time limit, timeLimit field
		["JAVA_MAIN_CLASS"] = task.languages.java.mainClass, -- it's almost always 'Main'
		["JAVA_TASK_CLASS"] = task.languages.java.taskClass, -- classname-friendly version of problem name
		["DATE"] = tostring(os.date(date_format)),
	}

	if remove_illegal_characters then
		for modifier, value in pairs(receive_modifiers) do
			if modifier ~= "HOME" and modifier ~= "CWD" then
				receive_modifiers[modifier] = string.gsub(value, '[<>:"/\\|?*]', "_")
			end
		end
	end

	return utils.format_string_modifiers(str, receive_modifiers)
end

--[[ Persistent receiver state ]]--
M._server = M._server or nil    -- our persistent TCP server
M._tasks  = {}                  -- accumulated tasks from clients
M._expected = nil               -- number of tasks to expect in current batch
M._callback = nil               -- callback to call once batch is complete
M._single_task = nil            -- flag: true if only a single task is expected

-- Local helper to process a client connection.
local function process_client(client)
	local message_chunks = {}  -- to accumulate received chunks
	client:read_start(function(err, chunk)
		assert(not err, err)
		if chunk then
			table.insert(message_chunks, chunk)
		else
			-- When read finishes, concatenate and extract the payload.
			local full_message = table.concat(message_chunks)
			-- (The original code extracts text after the last CRLF)
			local payload = string.match(full_message, "^.+\r\n(.+)$")
			if payload then
				local decoded = vim.json.decode(payload)
				table.insert(M._tasks, decoded)
				-- Set expected count if not already done.
				if not M._expected then
					M._expected = M._single_task and 1 or decoded.batch.size
				end
				M._expected = M._expected - 1
				if M._expected == 0 then
					-- All tasks received; schedule the callback.
					local tasks_to_return = M._tasks
					-- Reset for next batch.
					M._tasks = {}
					M._expected = nil
					vim.schedule(function()
						if M._callback then
							-- Disabled notification message here:
							-- utils.notify(notify .. " received successfully!", "INFO")
							M._callback(tasks_to_return)
						end
					end)
				end
			end
			-- Close the client connection (server remains open).
			if client and not client:is_closing() then
				client:shutdown()
				client:close()
			end
		end
	end)
end

---Wait for Competitive Companion to send tasks data persistently.
---The server is created once and remains open; each client connection is processed
---by accumulating received data until the full payload is read.
---@param port integer: competitive companion port to listen on
---@param single_task boolean: whether to parse a single task or all tasks
---@param notify string | nil: (currently ignored) notification string
---@param callback function: function called after data is received, accepting list of tasks as argument
function M.receive(port, single_task, notify, callback)
	-- Store the callback and single_task flag for use in client processing.
	M._callback = callback
	M._single_task = single_task

	-- If the persistent server is not already running, create and bind it.
	if not M._server then
		M._server = luv.new_tcp()
		M._server:bind("127.0.0.1", port)
		M._server:listen(128, function(err)
			assert(not err, err)
			-- Accept new client connection.
			local client = luv.new_tcp()
			M._server:accept(client)
			process_client(client)
		end)
		-- Optionally, you can notify the user that the persistent receiver is ready.
		-- if notify then utils.notify("Persistent receiver is ready on port " .. port, "INFO") end
	end
	-- (No need to restart the listener—the persistent server handles new connections.)
end

---Utility function to store received testcases
---@param bufnr integer: buffer number
---@param tclist table: table containing received testcases
---@param use_single_file boolean: whether to store testcases in a single file or not
---@param replace boolean: whether to replace existing testcases with received ones or to ask user what to do
function M.store_testcases(bufnr, tclist, use_single_file, replace)
	local tctbl = testcases.buf_get_testcases(bufnr)
	if next(tctbl) ~= nil then
		local choice = 2
		if not replace then
			choice = vim.fn.confirm("Some testcases already exist. Do you want to keep them along the new ones?", "Keep\nReplace\nCancel")
		end
		if choice == 2 then -- user chose "Replace"
			if not use_single_file then
				for tcnum, _ in pairs(tctbl) do
					testcases.io_files.buf_write_pair(bufnr, tcnum, nil, nil)
				end
			end
			tctbl = {}
		elseif choice == 0 or choice == 3 then -- user pressed <esc> or chose "Cancel"
			return
		end
	end

	local tcindex = 0
	for _, tc in ipairs(tclist) do
		while tctbl[tcindex] do
			tcindex = tcindex + 1
		end
		tctbl[tcindex] = tc
		tcindex = tcindex + 1
	end

	testcases.buf_write_testcases(bufnr, tctbl, use_single_file)
end

---Utility function to store received problem following configuration
---@param filepath string: source file absolute path
---@param confirm_overwriting boolean: whether to ask user to overwrite an already existing file or not
---@param task table: table with all task details
---@param cfg table: table containing competibest configuration
function M.store_problem_config(filepath, confirm_overwriting, task, cfg)
	if confirm_overwriting and utils.does_file_exist(filepath) then
		local choice = vim.fn.confirm('Do you want to overwrite "' .. filepath .. '"?', "Yes\nNo")
		if choice == 0 or choice == 2 then
			return
		end
	end

	local file_extension = vim.fn.fnamemodify(filepath, ":e")
	local template_file -- template file absolute path
	if type(cfg.template_file) == "string" then
		template_file = utils.eval_string(filepath, cfg.template_file)
	elseif type(cfg.template_file) == "table" then
		template_file = cfg.template_file[file_extension]
	end

	if template_file then
		template_file = string.gsub(template_file, "^%~", vim.loop.os_homedir())
		if not utils.does_file_exist(template_file) then
			if type(cfg.template_file) == "table" then
				utils.notify('template file "' .. template_file .. "\" doesn't exist.", "WARN")
			end
			template_file = nil
		end
	end

	local file_directory = vim.fn.fnamemodify(filepath, ":h")
	if template_file then
		if cfg.evaluate_template_modifiers then
			local str = utils.load_file_as_string(template_file)
			local evaluated_str = M.eval_receive_modifiers(str, task, file_extension, false, cfg.date_format)
			utils.write_string_on_file(filepath, evaluated_str or "")
		else
			utils.create_directory(file_directory)
			luv.fs_copyfile(template_file, filepath)
		end
	else
		utils.write_string_on_file(filepath, "")
	end

	local tctbl = {}
	local tcindex = 0
	for _, tc in ipairs(task.tests) do
		tctbl[tcindex] = tc
		tcindex = tcindex + 1
	end

	local tcdir = file_directory .. "/" .. cfg.testcases_directory .. "/"
	if cfg.testcases_use_single_file then
		local single_file_path = tcdir .. utils.eval_string(filepath, cfg.testcases_single_file_format)
		testcases.single_file.write(single_file_path, tctbl)
	else
		testcases.io_files.write_eval_format_string(tcdir, tctbl, filepath, cfg.testcases_input_file_format, cfg.testcases_output_file_format)
	end
end

return M

