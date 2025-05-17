#!/bin/bash

# Neovim Cheatsheet Display with YAD
# Adapted from https://github.com/JaKooLit

# GDK BACKEND: Use either 'wayland' or 'x11'
BACKEND=wayland

# Kill any existing yad or rofi instances
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Run YAD with the cheatsheet content
GDK_BACKEND=$BACKEND yad \
  --center \
  --title="Neovim Cheatsheet" \
  --no-buttons \
  --list \
  --column=Key: \
  --column=Description: \
  --column=Command: \
  --timeout-indicator=bottom \
"leader w" "Save file" ":w" \
"leader q" "Quit Neovim" ":q" \
"leader e" "Open file explorer" ":NvimTreeToggle" \
"" "" "" \
"leader ff" "Find files (Telescope)" ":Telescope find_files" \
"leader fg" "Live grep (Telescope)" ":Telescope live_grep" \
"leader fb" "Find buffers (Telescope)" ":Telescope buffers" \
"leader fh" "Find help (Telescope)" ":Telescope help_tags" \
"" "" "" \
"leader a" "Add file to Harpoon" ":lua require('harpoon.mark').add_file()" \
"leader h" "Harpoon menu" ":lua require('harpoon.ui').toggle_quick_menu()" \
"" "" "" \
"leader mp" "Markdown Preview" ":MarkdownPreview" \
"" "" "" \
"leader lv" "View LaTeX PDF" ":VimtexView" \
"" "" "" \
"leader ?" "Which-key overview" ":WhichKey" \
"" "" "" \
":UndotreeToggle" "Toggle undo tree" "Undo history view" \
":TroubleToggle" "Diagnostics list" "Trouble plugin" \
":Comment" "Comment lines" "Comment.nvim" \
":Lualine" "Status line" "Auto-managed" \
":Telescope" "Fuzzy finder" "Telescope main menu" \
"" "" "" \
"Legend" "Spacebar = leader " "Normal mode only"
