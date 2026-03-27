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

## Shell Config Structure

Shell configuration is split into shared and shell-specific files:

- **`.shellrc`** — shared config sourced by both `.zshrc` and `.bashrc` (env vars, PATH, aliases, functions like `tw`/`ts`)
- **`.zshrc`** — zsh-specific: keybindings, prompt (pure), completions (cached compinit), zsh tool hooks
- **`.bashrc`** — bash-specific: bash tool hooks

When adding new config, put it in `.shellrc` if it works in both shells. Only use `.zshrc`/`.bashrc` for shell-specific features (completions, prompts, keybindings, `--shell zsh`/`--shell bash` flags).

## Conventions

- Test changes with `chezmoi diff` or `chezmoi apply -n` before applying
- Use templates (`.tmpl`) when config varies by machine
- Use `run_onchange_` scripts for installing packages or running setup tasks
- Keep secrets encrypted with age — never commit plaintext secrets
- Put shared shell config in `.shellrc`, shell-specific config in `.zshrc`/`.bashrc`
