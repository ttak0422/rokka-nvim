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
		config_root = config.config_root,
		delay_time = config.delay_time,
		mods = config.mods,
		evs = config.evs,
		cmds = config.cmds,
		fts = config.fts,
	}
	local loader = require("rokka.loader").new(loader_config)
	loader:setup_module_loader()
	loader:setup_event_loader()
	loader:setup_cmd_loader()
	loader:setup_ft_loader()
	loader:setup_delay_loader()

	logger.info("rokka initialized...")
end

return rokka
