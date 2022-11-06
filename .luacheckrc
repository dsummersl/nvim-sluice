-- vim: ft=lua tw=80

-- Global objects defined by the C code
read_globals = {
  "vim",
}

std = "lua51"
files["tests/**/*_spec.lua"].std = "+busted"
