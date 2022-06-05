local rokka = {}

local logger = require "rokka.log"

rokka.init = function(config)

  local log_config = {
    plugin = config.log_plugin,
    level = config.log_level,
  }
  logger.new(log_config, true)

  local loader_config = {
    logger = logger,
    delay_plugins = config.loader_delay_plugins,
    delay_time = config.loader_delay_time,
  }

  loader = require("rokka.loader").new(loader_config)
  loader:setup_delay_loader()

  logger.info "rokka initialized..."
end

return rokka