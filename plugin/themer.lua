vim.api.nvim_create_user_command("Themer", function()
    require('themer').select_theme()
end, {})
