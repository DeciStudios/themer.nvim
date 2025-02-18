vim.api.nvim_create_user_command("ThemeSelect", function()
    require('themer').select_theme()
end, {})
