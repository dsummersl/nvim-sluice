---@meta

---@class Plugin
local Plugin = {}

---@class PluginSettings
---@field events string[]
---@field user_events string[]

---@class PluginLine
---@field text string          @The text of the line.
---@field linehl string        @The highlight group for the line.
---@field lnum integer         @The line number.
---@field priority integer     @The priority for the line.
---@field plugin string        @The plugin identifier for the line.

---Create a new Plugin instance.
---@param gutter_settings PluginSettings
---@param winid number
---@return Plugin
function Plugin:new(gutter_settings, winid) end

---Enable the plugin.
function Plugin:enable() end

---Disable the plugin.
function Plugin:disable() end

---Get lines for the plugin.
---@return PluginLine[] @Returns an array of Line objects.
function Plugin:get_lines() end
