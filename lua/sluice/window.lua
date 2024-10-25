local highlight = require('sluice.utils.highlight')
local counters = require('sluice.utils.counters')
local logger = require('sluice.utils.logger')
local guards = require('sluice.utils.guards')

local M = {}

--- Find the best match, ordered by priority.
-- @param matches List of matches from plugins.
-- @param optional key to prioritize by (beyond priority).
function M.find_best_match(matches, key)
  local best_match = nil
  for _, match in pairs(matches) do
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

--- Create a new window.
--- @param i number
--- @param column number
--- @param winid number
--- @return Window
function M.new(i, column, winid)
  local height = vim.api.nvim_win_get_height(winid)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local ns_id = vim.api.nvim_create_namespace('sluice' .. bufnr)

  local function open_window(ht)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      logger.log("window", "attempt to open a window for a buffer that no longer exists", "WARN")
      return false
    end

    return vim.api.nvim_open_win(bufnr, false, {
      relative = 'win',
      width = 1,
      height = ht,
      row = 0,
      col = column,
      focusable = false,
      style = 'minimal',
    })
  end

  local win_id = open_window(height)

  --- @class Window
  --- @field index number
  --- @field bufnr number
  --- @field ns_id number
  --- @field win_id number
  --- @field column number
  --- @field parent_winid number
  --- @field hide boolean
  local window = {
    index = i,
    bufnr = bufnr,
    ns_id = ns_id,
    win_id = win_id,
    width = 1,
    column = column,
    height = height,
    parent_winid = winid,
    hide = false,
  }

  local function guard()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      logger.log("window", "attempt to open a window for a buffer that no longer exists", "WARN")
      return false
    end
    if not guards.win_exists(window.win_id) then
      logger.log("window", "update_config: " .. window.win_id .. " not found", "WARN")
      return false
      -- window.win_id = open_window(window.height)
    end

    return true
  end

  --- Refresh the content of the gutter.
  --- @param lines PluginLine[]
  --- @param count_method table
  function window:set_gutter_lines(lines, count_method)
    if not guard() then return end

    local win_height = vim.api.nvim_win_get_height(window.parent_winid)

    local strings = {}
    for _, matches in pairs(lines) do
      local text = ' '
      local non_empty_matches = 0
      for _, match in pairs(matches) do
        if match.text ~= " " then
          non_empty_matches = non_empty_matches + 1
        end
      end
      if count_method ~= nil and non_empty_matches > 1 then
        text = counters.count(non_empty_matches, count_method)
      else
        text = M.find_best_match(matches, "text")['text']
      end

      table.insert(strings, text)
    end

    vim.api.nvim_buf_set_lines(window.bufnr, 0, win_height - 1, false, strings)
  end

  --- Add styling to the gutter.
  function window:refresh_highlights(lines)
    if not guard() then return end

    vim.api.nvim_buf_clear_namespace(window.bufnr, window.ns_id, 0, -1)
    for i2, matches in pairs(lines) do
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

  local function update_config()
    if not guard() then return end

    -- in case the window size changed, we can keep up with it.
    -- logger.log("window", "update_config: " .. window.win_id .. " height: " .. window.height .. " parent_winid: " .. window.parent_winid)
    vim.api.nvim_win_set_config(window.win_id, {
      win = window.parent_winid,
      relative = 'win',
      width = 1,
      height = window.height,
      row = 0,
      col = window.column,
      focusable = false,
      style = 'minimal',
      hide = window.hide,
    })
  end

  --- @param hidden boolean
  --- @param col number|nil
  function window:set_options(hidden, col)
    if not guard() then return end

    window.hide = hidden
    if col ~= nil then
      window.column = col
      window.height = vim.api.nvim_win_get_height(window.parent_winid)
    end
    update_config()
  end

  function window:teardown()
    vim.api.nvim_win_close(window.win_id, true)
    vim.api.nvim_buf_delete(window.bufnr, { force = true })
  end

  return window
end

return M
