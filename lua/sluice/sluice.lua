local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')
local Gutter = require('sluice.gutter')
local config = require('sluice.config')

local M = {}

--- Sluice: a collection of gutters overlaid on a window.
--- @return Sluice
function M.new(winid)
  --- @class IndexAndGutter
  --- @field index number
  --- @field gutter Gutter

  --- @class Sluice
  --- @field winid number
  --- @field au_id number|nil
  --- @field gutters IndexAndGutter[]
  local sluice = {
    winid = winid,
    gutters = {},
    au_id = nil,
  }

  local function get_gutter_column(gutter_index, layout)
    local window_width = (
      vim.api.nvim_win_get_width and vim.api.nvim_win_get_width(0) or 80
    )
    local column = 0
    local gutter_count = #sluice.gutters
    sluice:log("get_gutter_column: " .. gutter_index .. " " .. layout)

    if layout == 'right' then
      for i = gutter_count, gutter_index, -1 do
        local index_and_gutter = sluice.gutters[i]
        local gutter = index_and_gutter.gutter
        local gutter_settings = index_and_gutter.gutter.settings
        if gutter.enabled ~= false and gutter_settings.layout == 'right' then
          column = column + 1
        end
      end
      return window_width - column
    else -- 'left' layout
      for i = 1, gutter_index - 1 do
        local index_and_gutter = sluice.gutters[i]
        local gutter = index_and_gutter.gutter
        local gutter_settings = index_and_gutter.gutter.settings
        if gutter.enabled ~= false and gutter_settings.layout == 'left' then
          column = column + 1
        end
      end
      return column
    end
  end


  function sluice:enable()
    sluice:log("enable: " .. self.winid .. " gutters: ".. #config.settings.gutters)

    for i, gutter_settings in pairs(config.settings.gutters) do
      sluice.gutters[i] = {
        index = i,
        gutter = Gutter.new(i, gutter_settings, sluice.winid, function(layout)
          return get_gutter_column(i, layout)
        end)
      }
    end

    local function compute_columns()
      for _, v in pairs(sluice.gutters) do
        local gutter = v.gutter
        local column = get_gutter_column(v.index, gutter.settings.layout)
        gutter.window:set_options(false, column)
      end
    end

    local function update_window_size(ctx)
      if not guards.win_exists(sluice.winid) then
        sluice:log("get_lines: " .. sluice.winid .. " not found", "WARN")
        return {}
      end

      sluice:log('update_window_size triggered by ' .. ctx.event)

      compute_columns()
      sluice:update()
    end

    sluice.au_id = vim.api.nvim_create_autocmd({ "WinResized" }, {
      callback = update_window_size
    })

    compute_columns()
  end

  --- Open all gutters configured for this plugin.
  ---@return nil
  function sluice:update()
    sluice:log("update: " .. self.winid)

    for _, v in pairs(sluice.gutters) do
      v.gutter:update()
    end
  end

  --- Teardown all gutters
  ---@return nil
  function sluice:teardown()
    sluice:log("teardown: " .. self.winid)

    vim.api.nvim_del_autocmd(sluice.au_id)

    for _, v in pairs(sluice.gutters) do
      v.gutter:teardown()
    end
  end

  --- @param message string
  --- @param level string|nil
  function sluice:log(message, level)
    logger.log("".. sluice.winid ..":sluice:", message, level)
  end


  sluice:enable()
  sluice:update()

  return sluice
end

return M
