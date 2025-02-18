-- lua/theme-selector/init.lua
local M = {}
local api = vim.api
local fn = vim.fn

-- Default config
local config = {
    themes = {},
    width = 60,
    height = 20,
    border = "rounded",
    -- Add checkmark symbol (you can change this to your preferred nerdfont icon)
    checkmark = "",
}

-- Function to save theme to a file
local function save_theme(theme_name)
    local data_dir = vim.fn.stdpath('data')
    local theme_file = data_dir .. '/theme.txt'

    local file = io.open(theme_file, 'w')
    if file then
        file:write(theme_name)
        file:close()
    end
end

-- Function to load saved theme
local function load_saved_theme()
    local data_dir = vim.fn.stdpath('data')
    local theme_file = data_dir .. '/theme.txt'

    local file = io.open(theme_file, 'r')
    if file then
        local theme_name = file:read('*all')
        file:close()
        return theme_name
    end
    return nil
end

-- Apply theme
local function apply_theme(theme, is_preview)
    -- Set colorscheme with error handling
    local ok = pcall(vim.cmd, "colorscheme " .. theme.colorscheme)
    if not ok then return end

    -- Only save and update lualine for final selection, not preview
    if not is_preview then
        save_theme(theme.colorscheme)

        -- Update lualine
        -- local status_ok, lualine = pcall(require, "lualine")
        -- if status_ok then
        --     lualine.setup({
        --         options = {
        --             theme = theme.colorscheme
        --         }
        --     })
        -- end
    end
end

-- Fuzzy match function
local function fuzzy_match(str, pattern)
    if pattern == "" then return true end
    local pattern_len = #pattern
    local str_len = #str
    local p_idx = 1
    local s_idx = 1
    local match = false

    str = str:lower()
    pattern = pattern:lower()

    while s_idx <= str_len and p_idx <= pattern_len do
        if str:sub(s_idx, s_idx) == pattern:sub(p_idx, p_idx) then
            if p_idx == pattern_len then
                match = true
                break
            end
            p_idx = p_idx + 1
        end
        s_idx = s_idx + 1
    end

    return match
end

-- Create the preview window with search box
local function create_preview_window()
    local width = config.width
    local height = config.height + 1 -- Add 1 for search box

    -- Calculate position
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create buffer
    local buf = api.nvim_create_buf(false, true)

    -- Set buffer options to prevent modifications
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_buf_set_option(buf, 'buftype', 'nofile')

    -- Window options
    local win_opts = {
        relative = 'editor',
        row = row + 3, -- Move main window down by 1 for search box
        col = col,
        width = width,
        height = height - 1, -- Reduce height by 1 for search box
        style = 'minimal',
        border = config.border,
    }

    -- Create window
    local win = api.nvim_open_win(buf, true, win_opts)
    api.nvim_win_set_option(win, 'winblend', 0)
    api.nvim_win_set_option(win, 'cursorline', true)

    -- Create search buffer
    local search_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(search_buf, 'buftype', 'prompt')
    api.nvim_buf_set_option(search_buf, 'bufhidden', 'hide')

    -- Create search window with border
    local search_win = api.nvim_open_win(search_buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = 1,
        style = 'minimal',
        title = "Themer",
        title_pos = "center",
        border = config.border,
    })

    -- Set up prompt
    vim.fn.prompt_setprompt(search_buf, 'Search: ')

    return buf, win, search_buf, search_win
end

-- Show theme selector
function M.select_theme()
    local buf, win, search_buf, search_win = create_preview_window()
    local themes = config.themes
    local current_items = {}
    local saved_theme = load_saved_theme()
    local ns_id = api.nvim_create_namespace('themer_highlights')

    -- Function to update buffer content with fuzzy search
    local function update_buffer(filter)
        current_items = {}
        local lines = {}

        for _, theme in ipairs(themes) do
            if fuzzy_match(theme.name, filter) then
                table.insert(current_items, theme)
                -- Add padding for checkmark
                local line = "   " .. theme.name
                table.insert(lines, line)
            end
        end

        -- Clear existing highlights
        api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

        -- Allow buffer modification
        api.nvim_buf_set_option(buf, 'modifiable', true)

        -- Update lines
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        -- Add checkmarks and highlights
        for i, theme in ipairs(current_items) do
            -- Add checkmark for saved theme
            if theme.colorscheme == saved_theme then
                api.nvim_buf_add_highlight(buf, ns_id, 'DiagnosticOk', i - 1, 0, 3)
                api.nvim_buf_set_text(buf, i - 1, 0, i - 1, 1, { config.checkmark })
            end
        end

        -- Disable modification again
        api.nvim_buf_set_option(buf, 'modifiable', false)

        -- If we have filtered results, preview the first one
        if #current_items > 0 then
            M.move_cursor(win, buf, ns_id, current_items, 1)
        end
    end

    -- Initial content
    update_buffer("")

    -- Store buffer-local variables
    vim.b[buf] = {
        current_items = current_items
    }

    -- Set up autocommand for search buffer changes
    vim.api.nvim_create_autocmd("TextChanged", {
        buffer = search_buf,
        callback = function()
            local search_text = vim.api.nvim_buf_get_lines(search_buf, 0, -1, false)[1]:gsub("^Search: ", "")
            update_buffer(search_text)
        end
    })

    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = search_buf,
        callback = function()
            local search_text = vim.api.nvim_buf_get_lines(search_buf, 0, -1, false)[1]:gsub("^Search: ", "")
            update_buffer(search_text)
        end
    })

    -- Set up highlight groups
    vim.api.nvim_set_hl(0, 'ThemerSelected', { link = 'Visual' })
    vim.api.nvim_set_hl(0, 'DiagnosticOk', { fg = 'Green' })

    -- Handle navigation and selection
    vim.keymap.set('i', '<Up>', function()
        if #current_items == 0 then return end
        local pos = api.nvim_win_get_cursor(win)[1] - 1
        if pos == 0 then
            pos = #current_items
        end
        M.move_cursor(win, buf, ns_id, current_items, pos)
    end, { buffer = search_buf, noremap = true, silent = true })

    vim.keymap.set('i', '<Down>', function()
        if #current_items == 0 then return end
        local pos = api.nvim_win_get_cursor(win)[1] + 1
        if pos > #current_items then
            pos = 1
        end
        M.move_cursor(win, buf, ns_id, current_items, pos)
    end, { buffer = search_buf, noremap = true, silent = true })

    vim.keymap.set('i', '<CR>', function()
        if #current_items == 0 then return end
        local idx = api.nvim_win_get_cursor(win)[1]
        local selected = current_items[idx]
        if selected then
            apply_theme(selected, false)
            pcall(api.nvim_win_close, win, true)
            pcall(api.nvim_win_close, search_win, true)
            pcall(api.nvim_buf_delete, buf, { force = true })
            pcall(api.nvim_buf_delete, search_buf, { force = true })
            vim.cmd('stopinsert')
        end
    end, { buffer = search_buf, noremap = true, silent = true })

    vim.keymap.set('i', '<Esc>', function()
        local colorscheme = load_saved_theme()
        if type(colorscheme) == "string" then
            apply_theme({ colorscheme = colorscheme }, false)
        end
        pcall(api.nvim_win_close, win, true)
        pcall(api.nvim_win_close, search_win, true)
        pcall(api.nvim_buf_delete, buf, { force = true })
        pcall(api.nvim_buf_delete, search_buf, { force = true })
        vim.cmd('stopinsert')
    end, { buffer = search_buf, noremap = true, silent = true })

    --Get current theme and set cursor to it
    for i, theme in ipairs(current_items) do
        if theme.colorscheme == saved_theme then
            M.move_cursor(win, buf, ns_id, current_items, i)
            break
        end
    end

    -- Start in insert mode
    vim.cmd('startinsert')
end

function M.move_cursor(win, buf, ns_id, current_items, index)
    local idx = math.min(#current_items, index)
    api.nvim_win_set_cursor(win, { idx, 0 })
    local selected = current_items[idx]
    if selected then
        apply_theme(selected, true)
        api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
        api.nvim_buf_add_highlight(buf, ns_id, 'Bold', idx - 1, 0, -1)
        vim.api.nvim_set_hl(0, 'Bold', { bold = true })
        api.nvim_buf_add_highlight(buf, ns_id, 'ThemerFaded', idx - 1, 0, -1)
        vim.api.nvim_set_hl(0, 'ThemerFaded', { link = 'Function' })
    end
end

-- Setup function
function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
    -- Load saved theme on startup
    local saved_theme = load_saved_theme()
    if saved_theme then
        for _, theme in ipairs(config.themes) do
            if theme.colorscheme == saved_theme then
                apply_theme(theme, false)
                break
            end
        end
    end
end

return M
