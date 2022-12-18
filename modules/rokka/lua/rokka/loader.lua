local loader = {}

local group_name = "rokka_loader"

local function do_config(self, plugin_name)
	-- file exists are garanteed by nix.
	local ok, err_msg = pcall(dofile, self.plugins_config_root .. plugin_name)
	if not ok then
		err_msg = err_msg or "-- no msg --"
		self.logger.warn("[" .. plugin_name .. "] configure error: " .. err_msg)
	end
end

local function load_opt_plugin(self, plugin_name, chain)
	local plugin = require("rokka.gen.depends")[plugin_name]
	chain = chain or {}
	chain[plugin_name] = true

	if plugin == nil then
		self.logger.warn("opt plugin not found.", plugin_name)
		return
	end

	if plugin.loaded then
		self.logger.debug("loaded ", plugin_name)
		return
	end

	self.logger.debug("[Start] load ", plugin_name)

	-- resolve dependencies.
	for _, v in ipairs(plugin.opt_depends or {}) do
		if not chain[v] then
			self:load_opt_plugin(v, chain)
		end
	end

	vim.cmd("packadd " .. plugin_name)

	for _, v in ipairs(plugin.opt_depends_after or {}) do
		if not chain[v] then
			self:load_opt_plugin(v, chain)
		end
	end

	self:do_config(plugin_name)

	-- update status.
	plugin.loaded = true
end

local function setup_module_loader(self)
	self.logger.debug("[Setup] module loader.")

	local function custom_loader(module_name)
		local plugins = self.module_plugins[module_name]
		if not plugins or plugins.flag then
			return nil
		end
		plugins.flag = true
		self.logger.debug("[Start] load plugin (module).", module_name)
		for _, plugin in ipairs(plugins) do
			self:load_opt_plugin(plugin)
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
		for _, plugin in ipairs(require("rokka.gen.delay")) do
			self:load_opt_plugin(plugin)
		end
		self.logger.debug("[End] load plugin (delay).")
	end, self.delay_time)
end

local function setup_event_loader(self)
	self.logger.debug("[Setup] event loader.")
	-- for e, ps in pairs(self.event_plugins) do
	for _, e in ipairs(require("rokka.gen.events")) do
		self.logger.debug("[Setup] event.", e)
		vim.api.nvim_create_autocmd({ e }, {
			group = self.group_name,
			pattern = "*",
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (event).", e)
				for _, p in ipairs(require("rokka.gen.event." .. e)) do
					self:load_opt_plugin(p)
				end
				self.logger.debug("[End] load plugin (event).", e)
			end,
		})
	end
end

local function setup_cmd_loader(self)
	self.logger.debug("[Setup] cmd loader.")
	for _, cmd in ipairs(require("rokka.gen.cmds")) do
		self.logger.debug("[Setup] cmd.", cmd)
		vim.api.nvim_create_autocmd({ "CmdUndefined" }, {
			group = self.group_name,
			pattern = cmd,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (cmd).", cmd)
				for _, plugin in ipairs(require("rokka.gen.cmd." .. cmd)) do
					self:load_opt_plugin(plugin)
				end
				self.logger.debug("[End] load plugin (cmd).", cmd)
			end,
		})
	end
end

local function setup_ft_loader(self)
	self.logger.debug("[Setup] ft loader.")
	for _, ft in ipairs(require("rokka.gen.fts")) do
		self.logger.debug("[Setup] ft.", ft)
		vim.api.nvim_create_autocmd({ "FileType" }, {
			group = self.group_name,
			pattern = ft,
			once = true,
			callback = function()
				self.logger.debug("[Start] load plugin (ft).", ft)
				for _, plugin in ipairs(require("rokka.gen.ft." .. ft)) do
					self:load_opt_plugin(plugin)
				end
				self.logger.debug("[End] load plugin (ft).", ft)
			end,
		})
	end
end

function loader.new(config)
	vim.api.nvim_create_augroup(group_name, { clear = true })

	local tbl = {
		logger = config.logger,
		opt_plugins = config.opt_plugins,
		plugins_config_root = config.plugins_config_root,
		module_plugins = config.module_plugins,
		event_plugins = config.event_plugins,
		cmd_plugins = config.cmd_plugins,
		ft_plugins = config.ft_plugins,
		delay_plugins = config.delay_plugins,
		delay_time = config.delay_time,
	}
	tbl.load_opt_plugin = load_opt_plugin
	tbl.do_config = do_config
	tbl.setup_module_loader = setup_module_loader
	tbl.setup_event_loader = setup_event_loader
	tbl.setup_cmd_loader = setup_cmd_loader
	tbl.setup_ft_loader = setup_ft_loader
	tbl.setup_delay_loader = setup_delay_loader
	return tbl
end

return loader
