-- File: duras_bridge.lua
-- Description: Neovim integration layer for duras CLI
-- Maintainer: Sergiy Duras
-- SPDX-License-Identifier: ISC
-- Repository: https://github.com/sduras/duras_bridge
--
-- Notes:
-- - minimal bridge between buffer, clipboard, and duras


if vim.g.loaded_duras_bridge then return end
vim.g.loaded_duras_bridge = true

local function clip_get()
    if vim.fn.executable('pbpaste') == 1 then
        local text = vim.fn.trim(vim.fn.system('pbpaste'))
        if vim.v.shell_error == 0 then return text end
    end
    if vim.fn.executable('xclip') == 1 then
        local text = vim.fn.trim(vim.fn.system('xclip -selection clipboard -o'))
        if vim.v.shell_error == 0 then return text end
    end
    if vim.fn.executable('xsel') == 1 then
        local text = vim.fn.trim(vim.fn.system('xsel --clipboard --output'))
        if vim.v.shell_error == 0 then return text end
    end
    return vim.fn.getreg('+')
end

local function clip_set(text)
    vim.fn.setreg('+', text)
    if vim.fn.executable('pbcopy') == 1 then
        vim.fn.system('pbcopy', text)
    elseif vim.fn.executable('xclip') == 1 then
        vim.fn.system('xclip -selection clipboard', text)
    elseif vim.fn.executable('xsel') == 1 then
        vim.fn.system('xsel --clipboard --input', text)
    end
end


local function buf_get()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return table.concat(lines, '\n')
end


local function d_open(arg)
    local cmd = (arg == '') and 'duras path' or ('duras path ' .. vim.fn.shellescape(arg))
    local path = vim.fn.trim(vim.fn.system(cmd))

    if vim.v.shell_error ~= 0 or path == '' then
        vim.api.nvim_err_writeln('duras: path failed')
        return
    end

    if vim.fn.filereadable(path) == 0 then
        local open_cmd = (arg == '') and 'duras open' or ('duras open ' .. vim.fn.shellescape(arg))
        vim.fn.system('EDITOR=echo ' .. open_cmd)
        if vim.v.shell_error ~= 0 then
            vim.api.nvim_err_writeln('duras: failed to initialise note')
            return
        end
    end

    vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

vim.api.nvim_create_user_command('DOpen', function(opts)
    d_open(opts.args)
end, { nargs = '?' })


vim.api.nvim_create_user_command('DAppend', function(opts)
    local arg = opts.args
    local text
    if arg == '-' then
        text = clip_get()
    elseif arg ~= '' then
        text = arg
    else
        local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
        text = table.concat(lines, '\n')
    end
    vim.fn.system('duras append -', text)
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_err_writeln('duras: append failed')
    end
end, { range = '%', nargs = '*' })



local function d_search(q)
    local out = vim.fn.system('duras search ' .. vim.fn.shellescape(q))
    if vim.v.shell_error ~= 0 or vim.fn.trim(out) == '' then
        print('No results')
        return
    end

    local lines = vim.split(out, '\n', { trimempty = true })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_name(buf, '[duras-search]')
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false

    vim.cmd('belowright split')
    vim.api.nvim_win_set_buf(0, buf)
    vim.wo.wrap = false
    vim.wo.cursorline = true

    vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local date = line:match('^%d%d%d%d%-%d%d%-%d%d')
        if not date then return end
        vim.api.nvim_buf_delete(buf, { force = true })
        d_open(date)
    end, { buffer = buf, silent = true })
end

vim.api.nvim_create_user_command('DSearch', function(opts)
    d_search(opts.args)
end, { nargs = '+' })


vim.api.nvim_create_user_command('DClipYank', function()
    clip_set(buf_get())
end, {})

vim.api.nvim_create_user_command('DClipPaste', function()
    local text = clip_get()
    if text == '' then
        vim.api.nvim_err_writeln('duras: clipboard is empty')
        return
    end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(text, '\n'))
end, {})



vim.api.nvim_create_user_command('DStats', function()
    print(vim.fn.system('duras stats'))
end, {})

vim.api.nvim_create_user_command('DPath', function()
    print(vim.fn.trim(vim.fn.system('duras path')))
end, {})

vim.api.nvim_create_user_command('DCopyPath', function()
    clip_set(vim.fn.trim(vim.fn.system('duras path')))
end, {})

vim.api.nvim_create_user_command('DTags', function(opts)
    local tag = opts.args
    local cmd = (tag == '') and 'duras tags' or ('duras tags ' .. vim.fn.shellescape(tag))
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 or vim.fn.trim(out) == '' then
        print('No tags')
        return
    end
    print(out)
end, { nargs = '?' })


vim.keymap.set('n', '<leader>do', ':DOpen<CR>',   { silent = true })
vim.keymap.set('n', '<leader>ds', ':DSearch ',    {})
vim.keymap.set('n', '<leader>da', ':DAppend<CR>', { silent = true })
vim.keymap.set('v', '<leader>da', ':DAppend<CR>', { silent = true })
vim.keymap.set('n', '<leader>dp', ':DPath<CR>',   { silent = true })

