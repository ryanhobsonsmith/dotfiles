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

## Conventions

- Test changes with `chezmoi diff` or `chezmoi apply -n` before applying
- Use templates (`.tmpl`) when config varies by machine
- Use `run_onchange_` scripts for installing packages or running setup tasks
- Keep secrets encrypted with age — never commit plaintext secrets
- Put shared shell config in `.shellrc`, shell-specific config in `.zshrc`/`.bashrc`
