local highlight = require('sluice.utils.highlight')
local counters = require('sluice.utils.counters')
local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')
local config = require('sluice.config')

local M = {}

--- Find the best match, ordered by priority.
-- @param matches List of matches from plugins.
-- @param optional key to prioritize by (beyond priority).
function M.find_best_match(matches, key)
  local best_match = nil
  for _, match in ipairs(matches) do
    if best_match == nil then
      best_match = match
    else
      if not (key ~= nil and match[key] == nil) then
        if best_match == nil then
          best_match = match
        elseif best_match.priority == nil then
          best_match = match
        elseif best_match.priority ~= nil and match.priority ~= nil and match.priority > best_match.priority then
          best_match = match
        end
      end
    end
  end

  return best_match
end

function M.get_gutter_column(gutters, gutter_index, layout)
  local window_width = (
    vim.api.nvim_win_get_width and vim.api.nvim_win_get_width(0) or 80
  )
  local column = 0
  local gutter_count = #gutters

  if layout == 'right' then
    for i = gutter_count, gutter_index, -1 do
      local gutter_settings = config.settings.gutters[i]
      if gutter_settings and gutters[i] and gutters[i].enabled ~= false and gutter_settings.layout == 'right' then
        column = column + gutter_settings.width
      end
    end
    return window_width - column
  else -- 'left' layout
    for i = 1, gutter_index - 1 do
      local gutter_settings = config.settings.gutters[i]
      if gutter_settings and gutters[i] and gutters[i].enabled ~= false and gutter_settings.layout == 'left' then
        column = column + gutter_settings.width
      end
    end
    return column
  end
end

function M.new(i, gutter_settings, winid)
  local window = {
    index = i,
    bufnr = nil,
    ns_id = nil,
    win_id = nil,
    au_id = nil,
    parent_winid = winid,
  }

  local gutter_width = gutter_settings.width
  local column = M.get_gutter_column(config.settings.gutters, window.index, gutter_settings.layout)
  local height = vim.api.nvim_win_get_height(window.parent_winid)

  window.bufnr = vim.api.nvim_create_buf(false, true)
  window.ns_id = vim.api.nvim_create_namespace('sluice' .. window.bufnr)
  window.win_id = vim.api.nvim_open_win(window.bufnr, false, {
    relative = 'win',
    width = gutter_width,
    height = height,
    row = 0,
    col = column,
    focusable = false,
    style = 'minimal',
  })

  local function update_window_size(ctx)
    if not guards.win_exists(window.parent_winid) then
      logger.log("window", "get_lines: " .. window.parent_winid .. " not found", "WARN")
      return {}
    end

    logger.log('window', 'update_window_size triggered by ' .. ctx.event)
    column = M.get_gutter_column(config.settings.gutters, window.index, gutter_settings.layout)
    height = vim.api.nvim_win_get_height(window.parent_winid)
    -- in case the window size changed, we can keep up with it.
    vim.api.nvim_win_set_config(window.win_id, {
      win = window.parent_winid,
      relative = 'win',
      width = gutter_width,
      height = height,
      row = 0,
      col = column,
    })
  end

  --- Refresh the content of the gutter.
  function window:set_gutter_lines(lines, count_method, width)
    local win_height = vim.api.nvim_win_get_height(window.parent_winid)

    local strings = {}
    for _, matches in ipairs(lines) do
      local text = ' '
      local non_empty_matches = 0
      for _, match in ipairs(matches) do
        if match.text ~= " " then
          non_empty_matches = non_empty_matches + 1
        end
      end
      if count_method ~= nil and non_empty_matches > 1 then
        text = counters.count(non_empty_matches, count_method)
      else
        text = M.find_best_match(matches, "text")['text']
      end

      -- pad text to width
      text = string.rep(' ', width - vim.str_utfindex(text)) .. text
      table.insert(strings, text)
    end

    vim.api.nvim_buf_set_lines(window.bufnr, 0, win_height - 1, false, strings)
  end

  --- Add styling to the gutter.
  function window:refresh_highlights(lines)
    vim.api.nvim_buf_clear_namespace(window.bufnr, window.ns_id, 0, -1)
    for i2, matches in ipairs(lines) do
      local best_texthl_match = M.find_best_match(matches, "texthl")
      local best_linehl_match = M.find_best_match(matches, "linehl")
      local best_linehl = nil
      local best_texthl = nil
      if best_linehl_match ~= nil then
        best_linehl = best_linehl_match.linehl
      end
      if best_texthl_match ~= nil then
        best_texthl = best_texthl_match.texthl
      end

      if best_texthl ~= nil then
        local mode = "cterm"
        if vim.o.termguicolors then
          mode = "gui"
        end
        if best_linehl ~= nil then
          local line_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(best_linehl)), "bg", mode)
          local highlight_name = highlight.copy_highlight(best_texthl, mode == "gui", line_bg)
          vim.api.nvim_buf_add_highlight(window.bufnr, window.ns_id, highlight_name, i2 - 1, 0, -1)
        else
          vim.api.nvim_buf_add_highlight(window.bufnr, window.ns_id, best_texthl, i2 - 1, 0, -1)
        end
      else
        vim.api.nvim_buf_add_highlight(window.bufnr, window.ns_id, best_linehl, i2 - 1, 0, -1)
      end
    end
  end

  function window:close()
    logger.log("window", "cleanup: " .. vim.inspect(window.au_id), "WARN")
    vim.api.nvim_del_autocmd(window.au_id)
    vim.api.nvim_win_close(window.win_id, true)
    vim.api.nvim_buf_delete(window.bufnr, { force = true })
  end

  window.au_id = vim.api.nvim_create_autocmd({ "WinResized" }, {
    callback = update_window_size
  })

  -- TODO there should be a teardown function, and it should delete the autocmd.

  return window
end

return M
