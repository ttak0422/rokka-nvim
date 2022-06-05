local M = {}

-- WIP
function load_plugin(self, plugin_name)
   self.logger.debug("load plugin", plugin_name)
   vim.cmd("packadd " .. plugin_name)
end

function setup_delay_loader(self)
  self.logger.debug("[Setup] load plugin (delay).")
  vim.defer_fn(function ()
    self.logger.debug("[Start] load plugin (delay).")
    for _, plugin in ipairs(self.delay_plugins) do 
      self:load_plugin(plugin)
    end
    self.logger.debug("[End] load plugin (delay).")
  end, self.delay_time)
end

function M.new(config)
  local tbl = {
    logger = config.logger,
    delay_plugins = config.delay_plugins,
    delay_time = config.delay_time,
  }
  tbl.setup_delay_loader = setup_delay_loader
  tbl.load_plugin = load_plugin
  return tbl
end

return M