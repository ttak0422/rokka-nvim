local rokka = {}

-- local default_config = {
--   log_plugin = "rokka.nvim"
--   log_level = "warn"
-- }

rokka.init = function(config)
  local log_config = {
    plugin = config.log_plugin,
    level = config.log_level,
  }

  log = require "rokka.log"
  log.new(log_config, true)

  log.info "rokka initialized..."
end

return rokka