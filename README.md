# duras_bridge — Vim / Neovim integration

Minimal bridge between editor buffers, the system clipboard, and the
[duras](https://github.com/sduras/duras) CLI.

Requires duras 1.1.0 or later.

Two files. Same commands.

| File               | Editor              |
| ------------------ | ------------------- |
| `duras_bridge.vim` | Vim (incl. a-Shell) |
| `duras_bridge.lua` | Neovim              |

No dependencies. No plugin manager required.

---

## Installation

### Plugin manager

**Neovim — lazy.nvim**

```lua
{ url = 'https://github.com/sduras/duras_bridge' }
```

**Vim — vim-plug**

```vim
Plug 'https://github.com/sduras/duras_bridge'
```

**Vim — pathogen**

```sh
git clone https://github.com/sduras/duras_bridge ~/.vim/bundle/duras_bridge
```

The plugin files live in `plugin/`. Any manager that adds the repo root to
the runtimepath will load the correct file automatically — Vim sources
`duras_bridge.vim`, Neovim sources `duras_bridge.lua`. A shared guard
(`g:loaded_duras_bridge`) prevents both from loading on Neovim.

After install, run `:helptags ALL` (or let the plugin manager do it) to
enable `:help duras_bridge`.

---

### Manual — runtimepath

Clone once, point the editor at it:

```sh
git clone https://github.com/sduras/duras_bridge ~/src/duras_bridge
```

**Vim** — add to `.vimrc`:

```vim
set runtimepath+=~/src/duras_bridge
```

**Neovim** — add to `init.lua`:

```lua
vim.opt.runtimepath:append(vim.fn.expand('~/src/duras_bridge'))
```

To update: `git pull` in the cloned directory. No file copying needed.

---

### Manual — single file

If you prefer not to clone the repository, copy or symlink the plugin file
directly:

```sh
# Vim
cp plugin/duras_bridge.vim ~/.vim/plugin/

# Neovim
cp plugin/duras_bridge.lua ~/.config/nvim/plugin/
```

Verify it loaded:

```vim
:scriptnames
```

---

### Check prerequisites

```vim
:echo system('duras --version')
```

Clipboard (a-Shell / macOS):

```vim
:echo system('pbpaste')
```

Clipboard (Linux):

```vim
:echo system('xclip -selection clipboard -o')
```

If empty or error: fallback to `getreg('+')`.

---

## Commands

### Open

```vim
:DOpen            " today
:DOpen 2026-04-20
:DOpen -1         " offset
```

### Append

```vim
:DAppend          " buffer or selection
:DAppend text
:DAppend -        " clipboard
```

Text is normalized by duras before storage: trailing whitespace stripped
per line, consecutive blank lines collapsed to one, tabs converted to
spaces. This applies to all three input modes.

### Search

```vim
:DSearch keyword
:DSearch project meeting
```

Navigation:

- `<CR>` — open
- `:q` — close

### Clipboard

```vim
:DClipYank        " buffer → clipboard
:DClipPaste       " clipboard → below cursor
:DCopyPath        " note path → clipboard
```

### Metadata

```vim
:DStats
:DPath
:DTags
:DTags project
```

Pass tag names without `#`.

---

## Key bindings (default)

| Key          | Action      |
| ------------ | ----------- |
| `<leader>do` | `:DOpen`    |
| `<leader>da` | `:DAppend`  |
| `<leader>ds` | `:DSearch ` |
| `<leader>dp` | `:DPath`    |

Visual mode: `<leader>da` appends selection.

Disable by commenting mappings at file end:

- Vim: `nnoremap` / `vnoremap`
- Neovim: `vim.keymap.set`

No `no_mappings` guard.

---

## Clipboard behavior

Priority:

1. `pbcopy` / `pbpaste` (iOS, macOS)
2. `xclip` / `xsel` (X11)
3. `getreg('+')` / `setreg('+')`

All system calls checked by exit status.

---

## a-Shell notes

- Clipboard tools may be absent; fallback used
- `system()` is synchronous; large note sets may introduce latency

---

## Limitations

- Encrypted notes (`.dn.gpg`) unsupported — use `duras -c` in shell
- `:DAppend` always appends to today — use `duras append -d DATE text` in
  shell for past dates
- `:DSearch` has no `-i` flag — use `duras search -i` from shell

---

## Scope

- No background processes
- No state beyond buffer/clipboard
- No deviation from `duras` CLI behavior
