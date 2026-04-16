# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Setup

### Prerequisites

#### Required

| Tool | Install | Used by |
|---|---|---|
| [chezmoi](https://www.chezmoi.io/install/) | `brew install chezmoi` | Dotfile management |
| [age](https://github.com/FiloSottile/age) | `brew install age` | Encrypted dotfiles |
| [Ghostty](https://ghostty.org/) | `brew install ghostty` | Terminal emulator |
| [Hack](https://sourcefoundry.org/hack/) | `brew install font-hack` | Primary font (Ghostty uses built-in Nerd Font fallback for icons) |
| [tmux](https://github.com/tmux/tmux) | `brew install tmux` | Terminal multiplexer |
| [git](https://git-scm.com/) | `brew install git` | TPM install, chezmoi |
| [delta](https://github.com/dandavison/delta) | `brew install git-delta` | Git diff pager (side-by-side, syntax highlighting) |
| [fzf](https://github.com/junegunn/fzf) | `brew install fzf` | `ts`, tmux-sessionx |
| [fnm](https://github.com/Schniz/fnm) | `brew install fnm` | Node.js version management |
| [direnv](https://direnv.net/) | `brew install direnv` | Per-directory env vars |
| [Neovim](https://neovim.io/) | `brew install neovim` | `cts` dev layout, default editor |
| [starship](https://starship.rs/) | `brew install starship` | Shell prompt |
| [Claude Code](https://claude.ai/code) | `npm install -g @anthropic-ai/claude-code` | `cts` dev layout |
| [just](https://github.com/casey/just) | `brew install just` | Task runner (justfile) |
| [jq](https://jqlang.org/) | `brew install jq` | Merging rules into `karabiner.json` on `chezmoi apply` |
| [xclip](https://github.com/astrand/xclip) | `apt install xclip` / `pacman -S xclip` | Clipboard image paste in tmux (Linux only) |
| [docker](https://www.docker.com/) | Docker Desktop | Testing chezmoi config |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | `brew install karabiner-elements` | Key remapping, app hotkeys |

#### Optional

| Tool | Install | Used by |
|---|---|---|
| [rbenv](https://github.com/rbenv/rbenv) | `brew install rbenv` | Ruby version management |
| [uv](https://github.com/astral-sh/uv) | `brew install uv` | Python package management |
| [poetry](https://python-poetry.org/) | `pipx install poetry` | Python dependency management |
| [pnpm](https://pnpm.io/) | `brew install pnpm` | Node package manager |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | `brew install kubectl` | Kubernetes CLI |
| [aws](https://aws.amazon.com/cli/) | `brew install awscli` | AWS CLI |
| [bw](https://bitwarden.com/help/cli/) | `brew install bitwarden-cli` | Bitwarden secrets |
| [hub](https://hub.github.com/) | `brew install hub` | GitHub pull requests |
| [cargo](https://www.rust-lang.org/tools/install) | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | Rust toolchain |

SSH key at `~/.ssh/id_rsa` is used as the age identity for encrypted files.

### Install on a new machine

```sh
chezmoi init <your-repo-url>
chezmoi diff    # review what will change
chezmoi apply   # apply to home directory
```

### Post-install: macOS permissions

Karabiner requires manual permission grants in **System Settings > Privacy & Security > Accessibility**:

- `karabiner_grabber` — already prompted on install
- `karabiner_observer` — already prompted on install
- `karabiner_console_user_server` — **must be added manually** for `shell_command` rules (app switching hotkeys). Located at `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server`

Without `karabiner_console_user_server` in Accessibility, the app-switching hotkeys (Chrome profile switching via `osascript`/`System Events`) will silently fail.

### Day-to-day usage

```sh
chezmoi add ~/.some-config     # start managing a file
chezmoi edit ~/.some-config    # edit the source version
chezmoi diff                   # preview pending changes
chezmoi apply                  # apply changes to home
chezmoi update                 # pull from remote and apply
```

## What's managed

| File | Description |
|---|---|
| `.tmux.conf` | Tmux config (prefix `C-a`, vim bindings, Catppuccin Mocha, TPM plugins, two-line status bar) |
| `.config/ghostty/config` | Ghostty terminal config (Hack font, keybindings) |
| `.config/starship.toml` | Starship prompt config (minimal) |
| `.config/karabiner/karabiner.json` | Karabiner key remapping and app hotkeys (merge via `modify_` script — preserves device entries Karabiner writes) |
| `.shellrc` | Shared shell config sourced by both zsh and bash (env, PATH, aliases, functions) |
| `.zshrc` | Zsh-specific config (vi mode, history, completions, cursor shape, tool hooks) |
| `.zprofile` | Zsh login profile (Homebrew, pipx PATH) |
| `.bashrc` | Bash-specific config (bash tool hooks) |
| `.gitconfig` | Git configuration |
| `.gitignore` | Global gitignore |
| `.ssh/config` | SSH config (template) |
| `.vimrc` | Minimal vim config |
| `.actrc` | Act runner image mappings |
| `.config/direnv/direnvrc` | Direnv config |
| `.config/gh/config.yml` | GitHub CLI config |
| `.claude/settings.json` | Claude Code settings (symlinked) |
| `.claude/keybindings.json` | Claude Code keybindings (symlinked) |
| `.claude/hooks/block-home-dir.sh` | Claude Code hook (symlinked) |
| `.tmux/scripts/claude-tmux-hook.sh` | Claude Code hook for tmux status integration |
| `.tmux/scripts/claude-tmux-status.sh` | Reads claude state for tmux window tabs |
| `.tmux/scripts/session-list.sh` | Renders session bar with claude status icons |

Shell config is split so that shared settings (env vars, aliases, functions like `cts`/`ts`) live in `.shellrc` and are available in both shells. Shell-specific features (completions, prompts, keybindings) stay in `.zshrc`/`.bashrc`.

## Keyboard shortcuts

### Karabiner (global macOS hotkeys)

| Shortcut | Action |
|---|---|
| Caps Lock (tap) | Escape |
| Caps Lock (hold) | Ctrl |
| Cmd+Shift+Ctrl+T | Focus/launch Ghostty |
| Cmd+Shift+Ctrl+B | Focus/launch Chrome (Personal profile) |
| Cmd+Shift+Ctrl+W | Focus/launch Chrome (Work profile) |

### Ghostty keybindings

| Shortcut | Action |
|---|---|
| Cmd+N (1-9) | Switch tmux window N |
| Cmd+Ctrl+N (1-9) | Switch Ghostty tab N |
| Cmd+0 | Reset font size |

### Tmux keybindings (prefix = Ctrl+A)

| Shortcut | Action |
|---|---|
| prefix+v | Open VS Code at session workspace root |
| prefix+a | Jump to last window |
| prefix+A | Jump to last session |
| prefix+Q | Kill session, switch to previous |
| prefix+x | Kill pane |
| prefix+X | Kill window |
| prefix+\| | Split pane horizontal |
| prefix+- | Split pane vertical |
| prefix+Enter | Enter copy mode |
| prefix+r | Reload tmux config |
| prefix+b | Toggle focused mode (hide session list) |
| prefix+t | Toggle floating terminal popup |
| Alt+N (1-9) | Switch window N (no prefix needed) |
| Alt+,/. | Previous/next window (no prefix needed) |
| Ctrl+,/. | Previous/next window (no prefix needed) |
| Ctrl+Tab | Next window (no prefix needed) |
| Alt+h/j/k/l | Switch pane (no prefix needed) |

### Moving panes and windows

Run via `prefix+:`. Target syntax is `session:window.pane` — a bare `1` means **pane 1**, use `:1` for **window 1**.

| Command                       | Action                                           |
| ----------------------------- | ------------------------------------------------ |
| `join-pane -h -s :1`          | Join window 1 into current window as split      |
| `join-pane -s other:2.1`      | Pull pane from another session                   |
| `break-pane` (or `prefix+!`)  | Break current pane into its own window           |
| `break-pane -d -t other:`     | Break pane into a window in another session      |
| `move-window -t other:`       | Move whole window to another session             |
| `prefix+Space` / `prefix+z`   | Cycle layouts / zoom pane                        |

### Tmux status bar

Two-line status bar (Catppuccin Mocha theme):
- **Top line**: All tmux sessions — active session in lavender, inactive in muted gray
- **Bottom line**: Windows for the current session, with directory and session module on the right

#### Claude Code status indicators

Window tabs and session names show a color-coded 󰚩 icon reflecting Claude Code activity:
- **Peach** — Claude is working (thinking, using tools)
- **Red** — Claude needs attention (permission request, notification)
- **Grey** — Claude is idle (waiting for your next prompt)
- **No icon** — No Claude instance in that window/session

Powered by Claude Code hooks that write state to `/tmp/claude-tmux/`. Refresh rate is controlled by `status-interval` (default 15s).

## Tmux session management

### `cts` — create/attach project sessions

`cts` creates a tmux session for a directory with 3 windows (nvim, zsh, claude):

```sh
cts ~/projects/my-app   # create session with nvim, zsh, claude windows
cts                      # uses current directory
```

If the session already exists, it attaches (or switches if already inside tmux).

### `ts` — fuzzy session picker

`ts` uses fzf to fuzzy-find a project directory and opens it with `cts`:

```sh
ts   # scans ~/algebralabs and ~/projects, pick with fzf
```

### `alwt` — Algebra Labs worktree management

```sh
alwt -b feature-name       # create git worktree + Neon branch, then open cts session
alwt feature-name           # use existing worktree, open cts session
alwt                        # detect worktree from current directory, open cts session
```

### `alwt-stop` — tear down worktree session

```sh
alwt-stop                   # tear down current session's worktree
alwt-stop /path/to/worktree # tear down specific worktree
alwt-stop --force           # skip confirmation prompts
```

Kills all windows in the session (stops dev servers), opens a cleanup window to run `cleanup-worktree.sh` (removes git worktree + Neon branch), then kills the session and switches to the previous one.

## Testing

### Docker (Linux)

```sh
just build    # build test image
just test     # run verification checks
just shell    # interactive shell in clean container
just rebuild  # rebuild from scratch (no cache)
```

This won't cover macOS-specific behavior (e.g. Homebrew, Karabiner), but catches issues with file placement, templates, and script errors.

### macOS testing

Docker can't run macOS. For full macOS validation, consider:

- **[Tart](https://github.com/cirruslabs/tart)** — runs macOS VMs natively on Apple Silicon
- **Separate macOS user account** — create a test user and init chezmoi from your repo
