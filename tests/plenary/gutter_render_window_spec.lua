-- Tests for gutter render_window guard against invalid window IDs.
-- Regression test for: "Invalid window id" error when a window closes
-- before the vim.schedule callback in render_window fires.
local Gutter = require('sluice.gutter')

-- Helper: create a scratch buffer with enough lines to satisfy enabled checks
local function make_buf(line_count)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  for i = 1, line_count do
    lines[i] = 'line ' .. i
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  return buf
end

-- Helper: open a floating window (compatible with nvim 0.9+) and return its winid
local function open_win(buf)
  return vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    row = 0, col = 0,
    width = 20, height = 10,
    style = 'minimal',
  })
end

-- Flush the vim.schedule queue by spinning vim.wait for a short period.
local function flush_schedule()
  vim.wait(150, function() return false end)
end

describe('gutter render_window', function()
  it('does not call column_fn when window closes before scheduled callback', function()
    local buf = make_buf(200)
    local win = open_win(buf)

    local column_fn_called_when_invalid = false

    -- column_fn mirrors the real sluice.lua implementation:
    -- it calls nvim_win_get_width(winid), which throws "Invalid window id"
    -- when the window has already been closed.
    local column_fn = function(_layout)
      if not vim.api.nvim_win_is_valid(win) then
        column_fn_called_when_invalid = true
      end
      -- The real call that produces the error in the bug report:
      return vim.api.nvim_win_get_width(win)
    end

    local gutter = Gutter.new(1, {
      plugins = { 'viewport' },
      defer_updates_ms = 0,
      enabled = true,
    }, win, column_fn)

    -- Let the initial vim.schedule callback (from update_plugins) run.
    flush_schedule()

    -- Queue another render while the window is still open.
    gutter:update()

    -- Close the window immediately, BEFORE the scheduled callback fires.
    vim.api.nvim_win_close(win, true)

    -- Let the event loop tick so the scheduled callback runs.
    -- With the fix: guard sees the window is gone, returns early, column_fn is never called.
    -- Without the fix: column_fn is called, nvim_win_get_width throws "Invalid window id".
    flush_schedule()

    assert.is_false(
      column_fn_called_when_invalid,
      'column_fn must not be invoked after the parent window has been closed'
    )

    -- Cleanup
    pcall(function() gutter:teardown() end)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)

  it('calls column_fn normally when window is still open', function()
    local buf = make_buf(200)
    local win = open_win(buf)

    local column_fn_call_count = 0
    local column_fn = function(_layout)
      column_fn_call_count = column_fn_call_count + 1
      return vim.api.nvim_win_get_width(win)
    end

    local gutter = Gutter.new(1, {
      plugins = { 'viewport' },
      defer_updates_ms = 0,
      enabled = true,
    }, win, column_fn)

    flush_schedule()
    local calls_after_init = column_fn_call_count

    -- Queue another render while the window is still open.
    gutter:update()
    flush_schedule()

    -- column_fn should have been called at least once more after the second update.
    assert.is_true(
      column_fn_call_count > calls_after_init,
      'column_fn should be called when the window is valid'
    )

    -- Cleanup
    pcall(function() gutter:teardown() end)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end)
