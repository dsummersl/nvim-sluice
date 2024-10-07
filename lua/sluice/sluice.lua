local logger = require('sluice.utils.logger')
local Gutter = require('sluice.gutter')
local config = require('sluice.config')

local M = {
  vim = vim,
}

function M.new(winid)
  local sluice = {
    winid = winid,
    gutters = {},
  }

  function sluice:enable()
    logger.log("sluice", "enable: " .. self.winid .. " gutters: ".. #config.settings.gutters)

    for i, gutter_settings in ipairs(config.settings.gutters) do
      sluice.gutters[i] = {
        index = i,
        gutter = Gutter.new(i, gutter_settings, sluice.winid),
      }
    end
  end

  --- Open all gutters configured for this plugin.
  ---@return nil
  function sluice:update()
    logger.log("sluice", "update: " .. self.winid)

    for _, v in pairs(sluice.gutters) do
      v.gutter:update()
    end
  end

  --- Close all gutters
  ---@return nil
  function sluice:close()
    logger.log("sluice", "close: " .. self.winid)

    for _, v in pairs(sluice.gutters) do
      v.gutter:close()
    end
  end

  sluice:enable()
  sluice:update()

  return sluice
end

return M
