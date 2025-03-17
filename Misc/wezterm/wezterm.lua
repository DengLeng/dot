local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.font_size = 9.00
  config.font = wezterm.font("JetBrainsMono Nerd Font")
  config.default_prog = { "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" }
  config.window_background_opacity = 0.90
elseif wezterm.target_triple == "aarch64-apple-darwin" then
  config.font_size = 13.00
  config.font = wezterm.font("JetBrains Mono")
  config.default_prog = { "zsh", "-l" }
  config.window_background_opacity = 0.90
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
  config.font_size = 12.00
  config.font = wezterm.font("JetBrainsMono Nerd Font")
  config.default_prog = { "bash", "-l" }
  config.window_background_opacity = 0.80
end
config.color_scheme = "Catppuccin Mocha"
config.line_height = 1.00
config.default_cursor_style = "BlinkingBlock"
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}
config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = "NeverPrompt"

return config
