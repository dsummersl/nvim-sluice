local commands = require('sluice.commands')
local config = require('sluice.config')

local M = {
  vim = vim
}

M.setup = function(settings)
  config.apply_user_settings(settings)

  local subcommands = {
    enable = {
      impl = function(args, opts)
        commands.enable()
      end
    },
    disable = {
      impl = function(args, opts)
        commands.disable()
      end
    },
    toggle = {
      impl = function(args, opts)
        commands.toggle()
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

  if config.bool_table_fn(config.settings.enabled) then
    commands.enable()
  else
    commands.disable()
  end
end

return M
