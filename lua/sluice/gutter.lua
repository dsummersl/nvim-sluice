local M = {
  vim = vim,
  gutters = nil,
  gutter_lines = {},
}

local convert = require('sluice.utils.convert')
local logger = require('sluice.utils.logger')
local Window = require('sluice.window')
-- not used, just imported for typing.
require('sluice.plugins.plugin_type')

function M.new(i, gutter_settings, winid)
  local default_settings = {
    --- Width of the gutter.
    width = 1,

    --- Default highlight to use in the gutter.
    -- This serves as the base linehl highlight for a column in each gutter. Plugins can
    -- override parts of this highlight (typically this is the background color of
    -- areas represented in the gutter of offscreen content)
    gutter_hl = 'SluiceColumn',

    --- Whether to display the gutter or not.
    enabled = nil,

    --- When there are many matches in an area, how to show the number. Set to 'nil' to disable.
    count_method = nil,

    --- Layout of the gutter. Can be 'left' or 'right'.
    layout = 'right',

    --- Render method for the gutter. Can be 'macro' or 'line'.
    render_method = 'macro',

    plugins = { 'viewport' },
  }

  local update_settings = M.vim.tbl_deep_extend('keep', gutter_settings, default_settings)

  -- @class Gutter
  -- @field index number
  -- @field winid number
  -- @field bufnr number
  -- @field gutter_settings table
  -- @field window Window
  -- @field plugins Plugin[]
  -- @field event_autocammand_ids number[]
  -- @field lines PluginLine[]
  -- @field enabled boolean
  -- @type Gutter
  local gutter = {
    index = i,
    winid = winid,
    settings = update_settings,
    window = Window.new(i, update_settings),
    plugins = {},
    event_autocammand_ids = {},
    lines = {},
    enabled = false,
  }

  -- @return Plugin
  function gutter:make_plugin(plugin_settings)
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
    logger.log("gutter", "setup_events: " .. M.vim.inspect(events) .. " " .. M.vim.inspect(user_events))
    local results = {}
    local au_id = M.vim.api.nvim_create_autocmd(events, {
      callback = function(ctx)
        logger.log('gutter', 'triggered update by: '.. ctx.event)
        gutter:update()
      end,
    })
    table.insert(results, au_id)

    for _, value in ipairs(user_events) do
      local an_id M.vim.api.nvim_create_autocmd('User', {
        pattern = value,
        callback = function()
          logger.log('config', 'triggered update')
        end,
      })
      table.insert(results, an_id)
    end

    return results
  end

  function gutter:setup_plugins()
    logger.log("gutter", "setup_plugins: " .. gutter.index)
    for _, plugin_settings in ipairs(gutter.settings.plugins) do
      table.insert(gutter.plugins, gutter:make_plugin(plugin_settings))
    end

    -- get all unique events and user_events in all the plugins
    local all_events = {}
    local all_user_events = {}
    for _, plugin in ipairs(gutter.plugins) do
      for _, event in ipairs(plugin.settings.events) do
        if not M.vim.tbl_contains(all_events, event) then
          table.insert(all_events, event)
        end
      end
      for _, user_event in ipairs(plugin.settings.user_events) do
        if not M.vim.tbl_contains(all_user_events, user_event) then
          table.insert(all_user_events, user_event)
        end
      end
    end
    gutter:setup_events(all_events, all_user_events)
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
    local win_height = M.vim.api.nvim_win_get_height(0)
    local buf_lines = M.vim.api.nvim_buf_line_count(0)
    if win_height >= buf_lines then
      return false
    end
    if M.vim.fn.getwinvar(0, '&buftype') ~= '' then
      return false
    end
    if M.vim.fn.getwinvar(0, '&previewwindow') ~= 0 then
      return false
    end
    if M.vim.fn.getwinvar(0, '&diff') ~= 0 then
      return false
    end

    return true
  end

  function gutter:open()
    logger.log("gutter", "open: " .. gutter.index)
    gutter:update()
  end

  function gutter:close()
    logger.log("gutter", "close: " .. gutter.index)
  end

  function gutter:update()
    logger.log("gutter", "update: " .. gutter.index)

    local lines = {}
    for _, plugin in ipairs(gutter.plugins) do
      local plugin_lines = plugin:get_lines()
      for _, il in ipairs(plugin_lines) do
        table.insert(lines, il)
      end
    end

    gutter.lines = lines
    gutter.enabled = gutter.settings.enabled(gutter)
    gutter.gutter_lines = convert.lines_to_gutter_lines(gutter.settings, gutter.lines)

    M.vim.schedule(function()
      if gutter.enabled then
        gutter.window:set_gutter_lines(gutter.gutter_lines, gutter.settings.count_method, gutter.settings.width)
        gutter.window:refresh_highlights(gutter.gutter_lines)
      else
        gutter:close()
      end
    end)
  end

  gutter:setup_plugins()
  gutter:open()

  return gutter
end

return M
