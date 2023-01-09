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
	local plugin = self.opt_plugins[plugin_name]
	if plugin == nil then
		plugin = {}
	end

	if plugin.load then
		return
	end
	plugin.load = true

	self.logger.debug("[Start] load ", plugin_name)

	-- resolve dependencies.
	local depends = (plugin[1] and plugin[1] ~= 0) and plugin[1] or {}
	for _, idx in ipairs(depends) do
		self:load_opt_plugin(self.opt_plugin_names[idx])
	end

	vim.cmd("packadd " .. plugin_name)
	self:do_plugin_config(plugin_name)

	local depends_after = (plugin[2] and plugin[2] ~= 0) and plugin[2] or {}
	for _, idx in ipairs(depends_after) do
		self:load_opt_plugin(self.opt_plugin_names[idx])
	end

	plugin.loaded = true
end

local function setup_module_loader(self)
	self.logger.debug("[Setup] module loader.")

	local function custom_loader(module_name)
		local plugin_indexes = self.module_plugins[module_name]
		if not plugin_indexes or plugin_indexes.flag then
			return nil
		end
		plugin_indexes.flag = true
		self.logger.debug("[Start] load plugin (module).", module_name)
		for _, plugin_index in ipairs(plugin_indexes) do
			self:load_opt_plugin(self.opt_plugin_names[plugin_index])
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
	for e, plugin_indexes in pairs(self.event_plugins) do
		self.logger.debug("[Setup] event.", e)
		vim.api.nvim_create_autocmd({ e }, {
			group = self.group_name,
			pattern = "*",
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (event).", e)
				for _, plugin_index in ipairs(plugin_indexes) do
					self:load_opt_plugin(self.opt_plugin_names[plugin_index])
				end
				self.logger.debug("[End] load plugin (event).", e)
			end,
		})
	end
end

local function setup_cmd_loader(self)
	self.logger.debug("[Setup] cmd loader.")
	for cmd, plugin_indexes in pairs(self.cmd_plugins) do
		self.logger.debug("[Setup] cmd.", cmd)
		vim.api.nvim_create_autocmd({ "CmdUndefined" }, {
			group = self.group_name,
			pattern = cmd,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (cmd).", cmd)
				for _, plugin_index in ipairs(plugin_indexes) do
					self:load_opt_plugin(self.opt_plugin_names[plugin_index])
				end
				self.logger.debug("[End] load plugin (cmd).", cmd)
			end,
		})
	end
end

local function setup_ft_loader(self)
	self.logger.debug("[Setup] ft loader.")
	for ft, plugin_indexes in pairs(self.ft_plugins) do
		self.logger.debug("[Setup] ft.", ft)
		vim.api.nvim_create_autocmd({ "FileType" }, {
			group = self.group_name,
			pattern = ft,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (ft).", ft)
				for _, plugin_index in ipairs(plugin_indexes) do
					self:load_opt_plugin(self.opt_plugin_names[plugin_index])
				end
				self.logger.debug("[End] load plugin (ft).", ft)
			end,
		})
	end
end

function loader.new(cfg)
	vim.api.nvim_create_augroup(cfg.group_name, { clear = true })

	local tbl = {
		logger = cfg.logger,
		opt_plugin_names = cfg.opt_plugin_names,
		opt_plugins = cfg.opt_plugins,
		config_root = cfg.config_root,
		module_plugins = cfg.module_plugins,
		event_plugins = cfg.event_plugins,
		cmd_plugins = cfg.cmd_plugins,
		ft_plugins = cfg.ft_plugins,
		delay_plugins = cfg.delay_plugins,
		delay_time = cfg.delay_time,
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
