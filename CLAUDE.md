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

## Shell Config Structure

Shell configuration is split into shared and shell-specific files:

- **`.shellrc`** — shared config sourced by both `.zshrc` and `.bashrc` (env vars, PATH, aliases, functions like `tw`/`ts`)
- **`.zshrc`** — zsh-specific: keybindings, prompt (pure), completions (cached compinit), zsh tool hooks
- **`.bashrc`** — bash-specific: bash tool hooks

When adding new config, put it in `.shellrc` if it works in both shells. Only use `.zshrc`/`.bashrc` for shell-specific features (completions, prompts, keybindings, `--shell zsh`/`--shell bash` flags).

## App-Managed Config (Symlinks)

Some config files are edited by their applications (e.g., Claude Code, Karabiner, VS Code). These are managed as **symlinks** so changes stay in sync without needing `chezmoi re-add`.

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
| `~/.config/karabiner/karabiner.json` | `.data/karabiner/karabiner.json` |

### When to use symlinks vs copies vs modify templates

- **Symlinks** — for files apps frequently edit and you want the full file tracked (Claude, Karabiner, VS Code settings)
- **Copies** (default) — for files you control entirely (shell config, gitconfig)
- **Modify templates** (`modify_` + `setValueAtPath`) — for files where you only want to enforce specific keys while letting the app manage the rest. Uses `fromJson`/`toJson` pipeline to surgically set values without overwriting other keys.

## Tmux Config

- **Theme:** Catppuccin Mocha (via TPM plugin)
- **Two-line status bar:** `status 2` with custom `status-format[0]` (sessions) and `status-format[1]` (windows)
- Status modules (`status-left`, `status-right`) must be set **after** `run '~/.tmux/plugins/tpm/tpm'` so Catppuccin variables are defined
- `status-format[1]` uses the default tmux window list format (copied from tmux's built-in `status-format[0]`)
- Hex color codes (`#rrggbb`) inside `#{S:}` work fine — earlier issues were likely from other format nesting problems, not the hex codes themselves
- `session_attached` flag is true for **any** session with a client connected (not just the current one) — avoid using it to highlight the "active" session when multiple clients may be attached
- `#()` shell expansions inside catppuccin window pills (`@catppuccin_window_text`) cause pill backgrounds to missize — use tmux window options + format conditionals (`#{?#{==:#{@var},...}}`) instead

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
| `Stop` | `done` | green (`#a6e3a1`) |
| `Notification` | `waiting` | red (`#f38ba8`) |
| `PermissionRequest` | `waiting` | red (`#f38ba8`) |
| `SessionEnd` | *(file deleted)* | no icon |
| *(view window)* | `idle` (from `done`) | grey (`#6c7086`) |

**How it works:**
1. Hooks in `settings.json` call `~/.tmux/scripts/claude-tmux-hook.sh` on each event
2. The script writes state to `/tmp/claude-tmux/pane-{TMUX_PANE}.state` and sets `@claude_state` on both the tmux window and session (aggregated worst-state across all panes)
3. Window tabs use tmux format conditionals on window-level `@claude_state` (no `#()` — avoids pill sizing issues)
4. Session bar uses native `#{S:}` format with conditionals on session-level `@claude_state` — no shell scripts, no async `#()`, no flashing
5. State priority: `waiting` > `done` > `working` > `idle` (shows the state needing most attention)
6. Refresh rate is controlled by `status-interval` (default 15s, configurable in `dot_tmux.conf`)
7. Sessions are clickable via `#[range=session|$id]` markers in the `#{S:}` format

## Conventions

- Test changes with `chezmoi diff` or `chezmoi apply -n` before applying
- Use templates (`.tmpl`) when config varies by machine
- Use `run_onchange_` scripts for installing packages or running setup tasks
- Keep secrets encrypted with age — never commit plaintext secrets
- Put shared shell config in `.shellrc`, shell-specific config in `.zshrc`/`.bashrc`
