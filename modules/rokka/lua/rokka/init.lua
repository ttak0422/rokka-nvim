local rokka = {}

local logger = require("rokka.log")

rokka.init = function(config)
	-- log
	local log_config = {
		plugin = config.log_plugin,
		level = config.log_level,
	}
	logger.new(log_config, true)

	-- loader
	local loader_config = {
		logger = logger,
		opt_plugins = config.opt_plugins,
		event_plugins = config.loader_event_plugins,
		cmd_plugins = config.loader_cmd_plugins,
		ft_plugins = config.loader_ft_plugins,
		delay_plugins = config.loader_delay_plugins,
		delay_time = config.loader_delay_time,
	}
	local loader = require("rokka.loader").new(loader_config)
	loader:setup_delay_loader()
	loader:setup_event_loader()
	loader:setup_cmd_loader()
	loader:setup_ft_loader()

	logger.info("rokka initialized...")
end

return rokka
