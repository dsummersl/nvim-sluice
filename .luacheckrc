-- vim: ft=lua tw=80

-- Global objects defined by the C code
read_globals = {
  "vim", "it", "describe"
}

std = "lua51"
files["tests/**/*_spec.lua"].std = "+busted"
