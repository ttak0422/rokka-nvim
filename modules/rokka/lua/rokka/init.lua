local rokka = {}
local logger = require("rokka.log")
local group_name = "rokka_loader"

rokka.init = function(config)
	-- log
	local log_config = {
		plugin = config.log_plugin,
		level = config.log_level,
	}
	logger.new(log_config, true)

	-- loader
	local loader_config = {
		group_name = group_name,
		logger = logger,
		opt_plugin_names = config.opt_plugin_names,
		opt_plugins = config.opt_plugins,
		config_root = config.config_root,
		module_plugins = config.mod_ps,
		event_plugins = config.ev_ps,
		cmd_plugins = config.cmd_ps,
		ft_plugins = config.ft_ps,
		delay_time = config.loader_delay_time,
	}
	local loader = require("rokka.loader").new(loader_config)
	loader:setup_module_loader()
	loader:setup_event_loader()
	loader:setup_cmd_loader()
	loader:setup_ft_loader()

	vim.api.nvim_create_autocmd({ "VimEnter" }, {
		group = group_name,
		pattern = "*",
		once = true,
		callback = function()
			loader:setup_delay_loader()
		end,
	})
	logger.info("rokka initialized...")
end

return rokka
