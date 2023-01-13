local loader = {}

local function do_plugin_config(self, plugin_name)
	-- file exists are garanteed by nix.
	local ok, err_msg = pcall(dofile, self.config_root .. "/plugin/" .. plugin_name)
	if not ok then
		err_msg = err_msg or "-- no msg --"
		self.logger.warn("[" .. plugin_name .. "] configure error: " .. err_msg)
	end
end

local function load_opt_plugin(self, plugin_name)
	local loaded = self.plugin_loaded[plugin_name]
	if loaded then
		return nil
	end
	self.plugin_loaded[plugin_name] = true

	self.logger.debug("[Start] load ", plugin_name)

	-- resolve dependencies.
	local depends = dofile(self.config_root .. "/plugin/depends/" .. plugin_name)
	for _, p in ipairs(depends) do
		self:load_opt_plugin(p)
	end

	vim.cmd("packadd " .. plugin_name)
	self:do_plugin_config(plugin_name)

	local depends_after = dofile(self.config_root .. "/plugin/dependsAfter/" .. plugin_name)
	for _, p in ipairs(depends_after) do
		self:load_opt_plugin(p)
	end
end

local function setup_module_loader(self)
	self.logger.debug("[Setup] module loader.")

	local function custom_loader(module_name)
		local loaded = self.mods_loaded[module_name]
		if loaded then
			return nil
		end
		loaded = true

		local ok, ps = pcall(dofile, self.config_root .. "/mod/" .. module_name)
		if not ok then
			return nil
		end

		self.logger.debug("[Start] load plugin (module).", module_name)
		for _, p in ipairs(ps) do
			self:load_opt_plugin(p)
		end
		self.logger.debug("[End] load plugin (module).", module_name)
	end

	if not vim.g.rokka_custom_loader_enabled then
		table.insert(package.loaders, 1, custom_loader)
		vim.g.rokka_custom_loader_enabled = true
	end
end

local function setup_delay_loader(self)
	self.logger.debug("[Setup] delay loader.")
	vim.defer_fn(function()
		self.logger.debug("[Start] load plugin (delay).")
		for _, plugin in ipairs(dofile(self.config_root .. "/delayPlugins")) do
			self:load_opt_plugin(plugin)
		end
		self.logger.debug("[End] load plugin (delay).")
	end, self.delay_time)
end

local function setup_event_loader(self)
	self.logger.debug("[Setup] event loader.")
	for _, ev in ipairs(self.evs) do
		self.logger.debug("[Setup] event.", ev)
		vim.api.nvim_create_autocmd({ ev }, {
			group = self.group_name,
			pattern = "*",
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (event).", ev)
				for _, plugin in ipairs(dofile(self.config_root .. "/ev/" .. ev)) do
					self:load_opt_plugin(plugin)
				end
				self.logger.debug("[End] load plugin (event).", ev)
			end,
		})
	end
end

local function setup_cmd_loader(self)
	self.logger.debug("[Setup] cmd loader.")
	for _, cmd in ipairs(self.cmds) do
		self.logger.debug("[Setup] cmd.", cmd)
		vim.api.nvim_create_autocmd({ "CmdUndefined" }, {
			group = self.group_name,
			pattern = cmd,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (cmd).", cmd)
				for _, plugin in ipairs(dofile(self.config_root .. "/cmd/" .. cmd)) do
					self:load_opt_plugin(plugin)
				end
				self.logger.debug("[End] load plugin (cmd).", cmd)
			end,
		})
	end
end

local function setup_ft_loader(self)
	self.logger.debug("[Setup] ft loader.")
	for _, ft in ipairs(self.fts) do
		self.logger.debug("[Setup] ft.", ft)
		vim.api.nvim_create_autocmd({ "FileType" }, {
			group = self.group_name,
			pattern = ft,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (ft).", ft)
				for _, plugin in ipairs(dofile(self.config_root .. "/ft/" .. ft)) do
					self:load_opt_plugin(plugin)
				end
				self.logger.debug("[End] load plugin (ft).", ft)
			end,
		})
	end
end

function loader.new(cfg)
	vim.api.nvim_create_augroup(cfg.group_name, { clear = true })

	local tbl = {
		plugin_loaded = {},
		mods_loaded = {},
		group_name = cfg.group_name,
		logger = cfg.logger,
		config_root = cfg.config_root,
		delay_time = cfg.delay_time,
		mods = cfg.mods,
		evs = cfg.evs,
		cmds = cfg.cmds,
		fts = cfg.fts,
	}
	tbl.load_opt_plugin = load_opt_plugin
	tbl.do_plugin_config = do_plugin_config
	tbl.setup_module_loader = setup_module_loader
	tbl.setup_event_loader = setup_event_loader
	tbl.setup_cmd_loader = setup_cmd_loader
	tbl.setup_ft_loader = setup_ft_loader
	tbl.setup_delay_loader = setup_delay_loader
	return tbl
end

return loader
