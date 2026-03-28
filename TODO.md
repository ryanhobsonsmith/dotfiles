# TODO

## tweaks

- need to bring claude settings under chezmoi
- review candidates below and add to chezmoi as needed
- toggle between light and dark themes
- nvim config management and setup
- hotkeys for switching between terminal, vscode, browser (both profiles) and other common apps
- improve zsh functionality

## To Explore

- fish
- nushell
-

## Dotfiles/configs not yet managed by chezmoi

### Tier 1 — Simple files, no secrets, high value

- [x] `~/.gitconfig` (9 lines — name, email, pull, push, init)
- [x] `~/.gitignore` (1 line — global gitignore)
- [x] `~/.vimrc` (4 lines — minimal: syntax, filetype, term)
- [x] `~/.ssh/config` (72 lines — config only, NOT keys)
- [x] `~/.config/karabiner/karabiner.json` (45 lines — keyboard remapping)
- [x] `~/.config/direnv/direnvrc`
- [x] `~/.config/gh/config.yml` (GitHub CLI config)
- [x] `~/.claude/settings.json` + `~/.claude/keybindings.json` + `~/.claude/hooks/`
- [x] `~/.actrc` (4 lines — act runner image mappings)

### Tier 2 — Directories or moderate complexity

- [ ] `~/.config/nvim/` (LazyVim setup — `init.lua`, lua/config/, lua/plugins/, `stylua.toml`; skip auto-generated `lazy-lock.json`)
- [ ] VS Code: `~/Library/Application Support/Code/User/settings.json` + `keybindings.json`
- [ ] Cursor: `~/Library/Application Support/Cursor/User/settings.json` + `keybindings.json`
- [ ] `~/.config/htop/htoprc`
- [ ] `~/.mactop/config.json`

### Probably not worth managing

- `~/.zshrc_nvm` — NVM lazy-load, may be auto-generated
- `~/.iterm2_shell_integration.zsh` — legacy, no longer using iTerm2
- `~/.zcompdump` — auto-generated cache
- Tool-managed dirs: `~/.nvm/`, `~/.cargo/`, `~/.bun/`, `~/.rbenv/`
- Package caches: `~/.npm/`, `~/.yarn/`, `~/.gradle/`, `~/.m2/`
- History files: `.zsh_history`, `.bash_history`, `.psql_history`, etc.
- App internal state: `~/.ollama/`, `~/.cocoapods/`, `~/.android/`, `~/.expo/`

## Neovim

- Fix markdown files in lazyvim (too many diagnostic errors??)

## larger features

- need to figure out code-review/diffing in nvim or otherwise
- need to get nvim tutor or tutorial plan figured out

## Software To Install

- Bruno -> HTTP Testing Library
- Nushell -> Also good at HTTP Testing
- lm studio
- balena etcher
- freecad
- claude
- opencode
- docker
- chrome
- firefox?
- rectangle pro
- slack
- steam
- vscode
- vlc
- xcode
- tailscale
- logi options+
- bittwarden
- ghostty
- mimesstream
- ollama?
- bambu studio

### TODO: scan this comp and homebrew to identify critical casks/apps/packages I want to be able to manage/install

- Need to have a way split out install lists (minimal vs optional). With some way to select/alter/add eassily
