# Chezmoi Dotfiles

This repo manages dotfiles and shell environment for macOS using [chezmoi](https://www.chezmoi.io/).

## System

- **OS:** macOS (Darwin/arm64)
- **Shell:** zsh
- **Chezmoi config:** `~/.config/chezmoi/chezmoi.yaml`
- **Encryption:** age (symmetric, using `~/.ssh/id_rsa` as identity)

## Chezmoi Basics

- **Source directory:** `~/.local/share/chezmoi` (this repo)
- **Target directory:** `~` (home)
- Files in this repo use chezmoi naming conventions (e.g., `dot_zshrc` maps to `~/.zshrc`)
- Templates use `.tmpl` extension and Go template syntax
- Encrypted files use `.age` extension
- Scripts prefixed with `run_once_` or `run_onchange_` execute during `chezmoi apply`

### Common Commands

```sh
chezmoi add ~/.zshrc          # Add a file to source state
chezmoi edit ~/.zshrc         # Edit the source version
chezmoi diff                  # Show what would change
chezmoi apply                 # Apply source state to home
chezmoi apply -n              # Dry-run apply
chezmoi managed               # List managed files
chezmoi cat ~/.zshrc          # Show what chezmoi would write
chezmoi data                  # Show template data
chezmoi doctor                # Check setup health
```

### File Naming Conventions

| Prefix/Suffix | Meaning |
|---|---|
| `dot_` | File starts with `.` |
| `private_` | File is chmod 600 |
| `executable_` | File is chmod 755 |
| `encrypted_` | File is age-encrypted |
| `.tmpl` | File is a Go template |
| `run_once_` | Script that runs once |
| `run_onchange_` | Script that re-runs when its content changes |
| `create_` | Only create if file doesn't exist |
| `modify_` | Modify existing file |
| `symlink_` | Create a symlink (content = target path) |

## Package Installation

When adding a new required tool/package, update **all four** places:

1. **`README.md`** — add to the Required (or Optional) tools table
2. **`scripts/executable_install-macos.sh`** — add to the `brew bundle` heredoc
3. **`scripts/executable_install-ubuntu.sh`** — add to the `apt-get install` list (or install from source/releases if apt version is too old)
4. **`scripts/executable_install-arch.sh`** — add to the `pacman -Syu` list
5. **`test.sh`** — add a `command -v <tool>` verification check

Note: package names may differ across package managers (e.g. `git-delta` on brew/apt/pacman, but the binary is `delta`).

## Shell Config Structure

Shell configuration is split into shared and shell-specific files:

- **`.shellrc`** — shared config sourced by both `.zshrc` and `.bashrc` (env vars, PATH, aliases, functions like `tw`/`ts`)
- **`.zshrc`** — zsh-specific: keybindings, prompt (pure), completions (cached compinit), zsh tool hooks
- **`.bashrc`** — bash-specific: bash tool hooks

When adding new config, put it in `.shellrc` if it works in both shells. Only use `.zshrc`/`.bashrc` for shell-specific features (completions, prompts, keybindings, `--shell zsh`/`--shell bash` flags).

## App-Managed Config (Symlinks)

Some config files are edited by their applications (e.g., Claude Code, VS Code). These are managed as **symlinks** so changes stay in sync without needing `chezmoi re-add`.

Karabiner is the exception: it does atomic writes that replace the symlink with a regular file, so its config is managed via a `modify_` merge script instead (see below).

### How it works

1. The actual config file lives in `.data/` in the source dir (ignored by chezmoi, tracked by git)
2. A `symlink_<filename>.tmpl` in the chezmoi source creates a symlink from the target location back to `.data/`
3. The `.tmpl` suffix lets chezmoi resolve `{{ .chezmoi.sourceDir }}` to the correct absolute path — only the symlink target path is templated, not the file contents
4. When the app edits the file (e.g., `~/.claude/settings.json`), it follows the symlink and writes directly to the source dir
5. Changes appear in `git status` immediately — no `chezmoi re-add` needed

### Current symlinked files

| Target | Source (actual file) |
|---|---|
| `~/.claude/settings.json` | `.data/claude/settings.json` |
| `~/.claude/keybindings.json` | `.data/claude/keybindings.json` |
| `~/.claude/hooks/block-home-dir.sh` | `.data/claude/hooks/block-home-dir.sh` |

### Karabiner (modify_ script)

`~/.config/karabiner/karabiner.json` is merged on every `chezmoi apply` by `dot_config/private_karabiner/modify_private_karabiner.json`. The script:

1. Reads the live file via stdin (or bootstraps a minimal skeleton on first apply).
2. Uses `jq` to replace `profiles[0].complex_modifications.rules` with the union of our authored rules (from `.data/karabiner/desired-rules.json`) and any other rules Karabiner has added, matching by `description`.
3. Leaves everything else untouched — `devices`, `virtual_hid_keyboard`, `global`, UI state, and any rules you didn't author stay as Karabiner wrote them.

To change a hotkey or add a new rule, edit `.data/karabiner/desired-rules.json` and run `chezmoi apply`. Karabiner will pick up the new rules on its next config reload (or restart Karabiner-Elements).

### When to use symlinks vs copies vs modify scripts vs modify templates

- **Symlinks** — for files apps frequently edit and you want the full file tracked (Claude, VS Code settings). Doesn't work with apps that do atomic renames (Karabiner).
- **Copies** (default) — for files you control entirely (shell config, gitconfig).
- **Modify templates** (`modify_` + `setValueAtPath`) — for files where you only want to enforce a few scalar keys while letting the app manage the rest. Uses `fromJson`/`toJson` pipeline via Go templates.
- **Modify scripts** (`modify_` + `jq`) — for files where you need to merge by identity into arrays (e.g., Karabiner rules merged by `description`). The script receives the current file on stdin and outputs the new contents.

## Tmux Config

- **Theme:** Catppuccin Mocha (via TPM plugin)
- **Two-line status bar:** `status 2` with custom `status-format[0]` (sessions) and `status-format[1]` (windows)
- Status modules (`status-left`, `status-right`) must be set **after** `run '~/.tmux/plugins/tpm/tpm'` so Catppuccin variables are defined
- `status-format[1]` uses the default tmux window list format (copied from tmux's built-in `status-format[0]`)
- Hex color codes (`#rrggbb`) inside `#{S:}` work fine — earlier issues were likely from other format nesting problems, not the hex codes themselves
- `session_attached` flag is true for **any** session with a client connected (not just the current one) — avoid using it to highlight the "active" session when multiple clients may be attached
- `#()` shell expansions inside catppuccin window pills (`@catppuccin_window_text`) cause pill backgrounds to missize — use tmux window options + format conditionals (`#{?#{==:#{@var},...}}`) instead
- **Special characters in tmux conf files:** The Write/Edit tools silently strip powerline glyphs (U+E0B4 ``, U+E0B6 ``) and nerd font icons. When editing tmux conf files that contain these characters, use `printf` with hex escape sequences via the Bash tool instead. Key bytes: left roundcap `` = `\xee\x82\xb6`, right roundcap `` = `\xee\x82\xb4`, keyboard `󰌌` = `\xf3\xb0\x8c\x8c`, computer `󰲝` = `\xf3\xb0\xb2\x9d`, globe `󰖟` = `\xf3\xb0\x96\x9f`, docker `󰡨` = `\xf3\xb0\xa1\xa8`. Always verify with `xxd` after writing.

### Claude Code Status Integration

Claude Code hooks write per-pane state to `/tmp/claude-tmux/` and set tmux window options, providing visual status indicators in both the session bar and window tabs.

**Scripts** (in `dot_tmux/scripts/`, deployed to `~/.tmux/scripts/`):
- `claude-tmux-hook.sh` — Hook script called by Claude Code on state-change events. Writes state files and sets `@claude_state` window option (aggregated across panes).
- `claude-tmux-status.sh` — Reads state files for a window (used internally, available for future extensions).
- `claude-tmux-viewed.sh` — Called by tmux `after-select-window` hook; flips `done` → `idle` when user views a window.
- `session-list.sh` — Renders the session bar (top line) with per-session claude status icons. Sorted alphabetically, clickable via `#[range=session|$id]`.

**Hook events and states:**

| Event | State | Icon color |
|---|---|---|
| `SessionStart` | `idle` | grey (`#6c7086`) |
| `UserPromptSubmit` | `working` | peach (`#fab387`) |
| `PreToolUse` | `working` | peach (`#fab387`) |
| `PostToolUse` | `working` | peach (`#fab387`) |
| `Stop` | `done` | green (`#a6e3a1`) |
| `Notification` (permission_prompt, elicitation_dialog) | `waiting` | red (`#f38ba8`) |
| `Notification` (idle_prompt) | `done` | green (`#a6e3a1`) |
| `Notification` (auth_success) | *(no change)* | — |
| `SessionEnd` | *(file deleted)* | no icon |
| *(view window)* | `idle` (from `done` only) | grey (`#6c7086`) |

**How it works:**
1. Hooks in `settings.json` call `~/.tmux/scripts/claude-tmux-hook.sh` on each event
2. The script writes state to `/tmp/claude-tmux/pane-{TMUX_PANE}.state` and sets `@claude_state` on both the tmux window and session (aggregated worst-state across all panes)
3. Window tabs use tmux format conditionals on window-level `@claude_state` (no `#()` — avoids pill sizing issues)
4. Session bar is stored in the `@session_bar` tmux global option (written by `session-list.sh` on hook events) and rendered via `#{E:@session_bar}` in `status-format[0]`. This uses tmux format conditionals (`#{?#{==:#S,...}}`) for per-client active session highlighting, avoiding the stale-highlight bug of baking colors into a cache file. Sessions are sorted alphabetically.
5. State priority: `waiting` > `done` > `working` > `idle` (shows the state needing most attention)
6. Refresh rate is controlled by `status-interval` (default 15s, configurable in `dot_tmux.conf`)
7. Sessions are clickable via `#[range=session|$id]` markers in the cached output
8. Session bar rebuilds are triggered by: claude state hooks, `session-created`, `session-closed`, `session-renamed`, `client-session-changed`

## Conventions

- Test changes with `chezmoi diff` or `chezmoi apply -n` before applying
- Use templates (`.tmpl`) when config varies by machine
- Use `run_onchange_` scripts for installing packages or running setup tasks
- Keep secrets encrypted with age — never commit plaintext secrets
- Put shared shell config in `.shellrc`, shell-specific config in `.zshrc`/`.bashrc`
