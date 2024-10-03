local M = {
  vim = vim,
  buffers = {}
}

local commands = require('sluice2.commands')
local config = require('sluice2.config')
local gutter = require('sluice2.gutter')
local window = require('sluice2.window')

M.setup = function(settings)
  config.apply_user_settings(settings)

  -- Initialize buffer-specific data
  local function init_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    if not M.buffers[bufnr] then
      M.buffers[bufnr] = {
        enabled = false,
        gutter = gutter.new(bufnr),
        window = window.new(bufnr)
      }
    end
  end

  -- Create autocommand to initialize new buffers
  vim.api.nvim_create_autocmd({"BufEnter", "BufNew"}, {
    callback = init_buffer
  })

  local subcommands = {
    enable = {
      impl = function(args, opts)
        local bufnr = vim.api.nvim_get_current_buf()
        commands.enable(M.buffers[bufnr])
      end
    },
    disable = {
      impl = function(args, opts)
        local bufnr = vim.api.nvim_get_current_buf()
        commands.disable(M.buffers[bufnr])
      end
    },
    toggle = {
      impl = function(args, opts)
        local bufnr = vim.api.nvim_get_current_buf()
        commands.toggle(M.buffers[bufnr])
      end
    },
  }

  local function sluice_command(opts)
    local fargs = opts.fargs
    local subcommand_arg = fargs[1]
    local args = #fargs > 1 and {table.unpack(fargs, 2)} or {}
    local subcommand = subcommands[subcommand_arg]
    if not subcommand then
      vim.notify("Sluice: unknown command: " .. subcommand, vim.log.levels.ERROR)
      return
    end

    subcommand.impl(args, opts)
  end

  vim.api.nvim_create_user_command("Sluice", sluice_command, {
    nargs = "+",
    desc = "Sluice control commands",
    complete = function (arg_lead, cmdline, _)
      if cmdline:match("^Sluice%s+%w*$") then
        local keys = vim.tbl_keys(subcommands)
        return vim.iter(keys):filter(
          function(k) return k:match(arg_lead) ~= nil end
        ):totable()
      end
    end
  })

  -- Enable or disable for all current buffers based on the config
  for bufnr, _ in pairs(M.buffers) do
    if config.bool_table_fn(config.settings.enabled) then
      commands.enable(M.buffers[bufnr])
    else
      commands.disable(M.buffers[bufnr])
    end
  end
end

-- Don't call M.setup() here, let the user call it with their settings
return M
