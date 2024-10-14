local M = {}

local convert = require('sluice.utils.convert')
local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')
local Window = require('sluice.window')
-- not used, just imported for typing.
require('sluice.plugins.plugin_type')

--- Gutter: A single column of information overlaid on the left/right side of
--- a window.
--- @param i number Index of the gutter.
--- @param gutter_settings GutterSettings Settings for the gutter.
--- @param winid number Window ID to attach the gutter to.
--- @param column_fn fun(layout: string): integer Function to get the column of the gutter.
--- @return Gutter
function M.new(i, gutter_settings, winid, column_fn)
  --- @class GutterSettings
  --- @field width number
  --- @field gutter_hl string
  --- @field enabled function|boolean
  --- @field count_method table|nil
  --- @field layout string
  --- @field render_method string
  --- @field plugins table
  --- @type GutterSettings
  local default_settings = {
    --- Width of the gutter.
    width = 1,

    --- Default highlight to use in the gutter.
    -- This serves as the base linehl highlight for a column in each gutter. Plugins can
    -- override parts of this highlight (typically this is the background color of
    -- areas represented in the gutter of offscreen content)
    gutter_hl = 'SluiceColumn',

    --- Whether to display the gutter or not (boolean or function that takes this gutter)
    enabled = true,

    --- When there are many matches in an area, how to show the number. Set to 'nil' to disable.
    count_method = nil,

    --- Layout of the gutter. Can be 'left' or 'right'.
    layout = 'right',

    --- Render method for the gutter. Can be 'macro' or 'line'.
    render_method = 'macro',

    plugins = { 'viewport' },
  }

  local update_settings = vim.tbl_deep_extend('keep', gutter_settings, default_settings)

  --- @class Gutter
  --- @field index number
  --- @field winid number
  --- @field bufnr number
  --- @field settings GutterSettings
  --- @field window Window
  --- @field column number
  --- @field plugins Plugin[]
  --- @field event_au_ids number[]
  --- @field lines PluginLine[]
  --- @field enabled boolean
  local gutter = {
    index = i,
    winid = winid,
    settings = update_settings,
    column = 0,
    window = Window.new(i, 0, update_settings.width, winid),
    plugins = {},
    event_au_ids = {},
    lines = {},
    enabled = false,
  }

  --- @return Plugin
  local function make_plugin(plugin_settings)
    if type(plugin_settings) == "table" then
      logger.log("gutter", "make_plugin:".. plugin_settings[1])
      -- @type Plugin
      local PluginByTable = require('sluice.plugins.' .. plugin_settings[1])
      plugin_settings = plugin_settings[2]
      return PluginByTable.new(plugin_settings, gutter.winid)
    end

    logger.log("gutter", "make_plugin:".. plugin_settings)
    -- @type Plugin
    local PluginByString = require('sluice.plugins.' .. plugin_settings)
    plugin_settings = nil
    return PluginByString.new(PluginByString.default_settings, gutter.winid)
  end

  function gutter:setup_events(events, user_events)
    logger.log("gutter", "setup_events: " .. vim.inspect(events) .. " " .. vim.inspect(user_events))
    local results = {}
    local au_id = vim.api.nvim_create_autocmd(events, {
      callback = function(ctx)
        logger.log('gutter', 'triggered update by: '.. ctx.event)
        gutter:update()
      end,
    })
    table.insert(results, au_id)

    for _, user_au in ipairs(user_events) do
      local an_id = vim.api.nvim_create_autocmd('User', {
        pattern = user_au,
        callback = function()
          logger.log('config', 'triggered update')
          gutter:update()
        end,
      })
      table.insert(results, an_id)
    end

    return results
  end

  local function setup_plugins()
    logger.log("gutter", "setup_plugins: " .. gutter.index)
    for _, plugin_settings in ipairs(gutter.settings.plugins) do
      table.insert(gutter.plugins, make_plugin(plugin_settings))
    end

    -- get all unique events and user_events in all the plugins
    local all_events = {}
    local all_user_events = {}
    for _, plugin in ipairs(gutter.plugins) do
      for _, event in ipairs(plugin.settings.events) do
        if not vim.tbl_contains(all_events, event) then
          table.insert(all_events, event)
        end
      end
      for _, user_event in ipairs(plugin.settings.user_events) do
        if not vim.tbl_contains(all_user_events, user_event) then
          table.insert(all_user_events, user_event)
        end
      end
    end
    gutter.event_au_ids = gutter:setup_events(all_events, all_user_events)
  end

  --- Whether to display the gutter or not.
  --
  -- Returns boolean indicating whether the gutter is shown on screen or not.
  --
  -- Show the gutter if:
  -- - the buffer is not smaller than the window
  -- - the buffer is not a special &buftype
  -- - the buffer is not a &previewwindow
  -- - the buffer is not a &diff
  -- TODO this now needs to take in a win/bufnr b/c its not just the current one.
  function gutter:default_enabled()
    local win_height = vim.api.nvim_win_get_height(0)
    local buf_lines = vim.api.nvim_buf_line_count(0)
    if win_height >= buf_lines then
      return false
    end
    if vim.fn.getwinvar(0, '&buftype') ~= '' then
      return false
    end
    if vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
      return false
    end
    if vim.fn.getwinvar(0, '&diff') ~= 0 then
      return false
    end

    return true
  end

  -- Teardown this gutter and all its resources.
  function gutter:teardown()
    logger.log("gutter", "teardown: " .. gutter.index)
    gutter.window:teardown()
    gutter.enabled = false
    for _, au_id in pairs(gutter.event_au_ids) do
      vim.api.nvim_del_autocmd(au_id)
  end
    for _, plugin in ipairs(gutter.plugins) do
      plugin:disable()
    end
    gutter.event_au_ids = {}
  end

  function gutter:update()
    if not guards.win_exists(gutter.winid) then
      logger.log("gutter", "update: " .. gutter.winid .. " not found", "WARN")
      return
    end

    logger.log("gutter", "update: " .. gutter.index)

    local lines = {}
    for _, plugin in ipairs(gutter.plugins) do
      local plugin_lines = plugin:get_lines()
      for _, il in ipairs(plugin_lines) do
        table.insert(lines, il)
      end
    end

    gutter.lines = lines
    if type(gutter.settings.enabled) == "boolean" then
      gutter.enabled = gutter.settings.enabled and true
    else
      gutter.enabled = gutter.settings.enabled(gutter)
    end

    logger.log("gutter", "update: " .. gutter.index .. " enabled: " .. vim.inspect(gutter.enabled))
    gutter.gutter_lines = convert.lines_to_gutter_lines(gutter.settings, gutter.lines)

    vim.schedule(function()
      if gutter.enabled then
        gutter.window:set_options(false, column_fn(gutter.settings.layout))
        gutter.window:set_gutter_lines(gutter.gutter_lines, gutter.settings.count_method, gutter.settings.width)
        gutter.window:refresh_highlights(gutter.gutter_lines)
      else
        gutter.window:set_options(true)
      end
    end)
  end

  setup_plugins()
  gutter:update()

  return gutter
end

return M
