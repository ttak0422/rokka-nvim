local loader = {}

local group_name = "rokka_loader"

local function load_opt_plugin(self, plugin_name, chain)
  local plugin = self.opt_plugins[plugin_name]
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
  for _, v in ipairs(plugin.opt_depends) do
    if not(chain[v]) then
      self:load_opt_plugin(v, chain)
    end
  end

  vim.cmd("packadd " .. plugin_name)

  for _, v in ipairs(plugin.opt_depends_after) do
    if not(chain[v]) then
      self:load_opt_plugin(v, chain)
    end
  end

  -- apply config.
  if plugin.config then plugin.config() end

  -- update status.
  plugin.loaded = true
end

local function setup_delay_loader(self)
  self.logger.debug("[Setup] delay loader.")
  vim.defer_fn(function ()
    self.logger.debug("[Start] load plugin (delay).")
    for _, plugin in ipairs(self.delay_plugins) do self:load_opt_plugin(plugin) end
    self.logger.debug("[End] load plugin (delay).")
  end, self.delay_time)
end

local function setup_event_loader(self)
  self.logger.debug("[Setup] event loader.")
  for e, ps in pairs(self.event_plugins) do
    self.logger.debug("[Setup] event.", e)
    vim.api.nvim_create_autocmd({ e }, {
      group = self.group_name,
      pattern = "*",
      once = true,
      callback = function()
        self.logger.debug("[Start] load plugin (event).", e)
        for _, p in ipairs(ps) do self:load_opt_plugin(p) end
        self.logger.debug("[End] load plugin (event).", e)
      end,
    })
  end
end

local function setup_cmd_loader(self)
  self.logger.debug("[Setup] cmd loader.")
  for cmd, plugins in pairs(self.cmd_plugins) do
    self.logger.debug("[Setup] cmd.", cmd)
    vim.api.nvim_create_autocmd({ "CmdUndefined" }, {
      group = self.group_name,
      pattern = cmd,
      once = true,
      callback = function()
        self.logger.debug("[Start] load plugin (cmd).", cmd)
        for _, plugin in ipairs(plugins) do self:load_opt_plugin(plugin) end
        self.logger.debug("[End] load plugin (cmd).", cmd)
      end,
    })
  end
end

local function setup_ft_loader(self)
  self.logger.debug("[Setup] ft loader.")
  for ft, plugins in pairs(self.ft_plugins) do
    self.logger.debug("[Setup] ft.", ft)
    vim.api.nvim_create_autocmd({ "FileType" }, {
      group = self.group_name,
      pattern = ft,
      once = true,
      callback = function()
        self.logger.debug("[Start] load plugin (ft).", ft)
        for _, plugin in ipairs(plugins) do self:load_opt_plugin(plugin) end
        self.logger.debug("[End] load plugin (ft).", ft)
      end,
    })
  end
end

function loader.new(config)
  vim.api.nvim_create_augroup(group_name, { clear = true, })

  local tbl = {
    logger = config.logger,
    opt_plugins = config.opt_plugins,
    event_plugins = config.event_plugins,
    cmd_plugins = config.cmd_plugins,
    ft_plugins = config.ft_plugins,
    delay_plugins = config.delay_plugins,
    delay_time = config.delay_time,
  }
  tbl.load_opt_plugin = load_opt_plugin
  tbl.setup_event_loader = setup_event_loader
  tbl.setup_cmd_loader = setup_cmd_loader
  tbl.setup_ft_loader = setup_ft_loader
  tbl.setup_delay_loader = setup_delay_loader
  return tbl
end

return loader
