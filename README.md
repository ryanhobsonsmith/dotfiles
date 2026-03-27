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
| [Inconsolata Nerd Font](https://www.nerdfonts.com/) | `brew install font-inconsolata-nerd-font` | Ghostty, tmux icons |
| [tmux](https://github.com/tmux/tmux) | `brew install tmux` | Terminal multiplexer |
| [git](https://git-scm.com/) | `brew install git` | TPM install, chezmoi |
| [fzf](https://github.com/junegunn/fzf) | `brew install fzf` | `ts`, tmux-sessionx |
| [fnm](https://github.com/Schniz/fnm) | `brew install fnm` | Node.js version management |
| [direnv](https://direnv.net/) | `brew install direnv` | Per-directory env vars |
| [Neovim](https://neovim.io/) | `brew install neovim` | `tw` dev layout |
| [Claude Code](https://claude.ai/code) | `npm install -g @anthropic-ai/claude-code` | `tw` dev layout |
| [just](https://github.com/casey/just) | `brew install just` | Task runner (justfile) |
| [docker](https://www.docker.com/) | Docker Desktop | Testing chezmoi config |

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
| `.tmux.conf` | Tmux configuration (prefix `C-a`, vim bindings, Tokyo Night, TPM plugins) |
| `.config/ghostty/config` | Ghostty terminal config (Tokyo Night, Nerd Font, keybindings) |
| `.shellrc` | Shared shell config sourced by both zsh and bash (env, PATH, aliases, functions) |
| `.zshrc` | Zsh-specific config (keybindings, prompt, completions, zsh tool hooks) |
| `.zprofile` | Zsh login profile (Homebrew, pipx PATH) |
| `.bashrc` | Bash-specific config (bash tool hooks) |

Shell config is split so that shared settings (env vars, aliases, functions like `tw`/`ts`) live in `.shellrc` and are available in both shells. Shell-specific features (completions, prompts, keybindings) stay in `.zshrc`/`.bashrc`.

## Tmux session management

### `tw` — create/attach project sessions

`tw` creates a tmux session for a directory with a layout determined by the path:

```sh
tw ~/algebralabs/my-project   # "dev" layout: nvim + shell + claude
tw ~/random/thing              # "default" layout: plain session
tw                             # uses current directory
tw ~/anything --layout dev     # force a specific layout
```

If the session already exists, it attaches (or switches if already inside tmux).

#### Layouts

| Layout | Path pattern | Windows |
|---|---|---|
| `dev` | `*/algebralabs/*` | nvim, shell, claude |
| `default` | everything else | single shell |

To add a new layout, define a `_tw_layout_<name>` function in `.zshrc` and add a case to the path matcher in `tw`.

### `ts` — fuzzy session picker

`ts` uses fzf to fuzzy-find a project directory and opens it with `tw`:

```sh
ts   # scans ~/algebralabs and ~/projects, pick with fzf
```

Edit the `dirs` array in the `ts` function to add more search paths.

## Testing

### Docker (Linux)

A Dockerfile is provided to validate the chezmoi config in a clean Linux environment. This tests that files are placed correctly, templates render properly, and `run_once_` scripts succeed.

```sh
docker build -t dotfiles-test .
docker run --rm dotfiles-test
```

This won't cover macOS-specific behavior (e.g. Homebrew installs, macOS defaults), but catches most issues with file placement, templates, and script errors.

Scripts that need to behave differently per OS should use platform guards:

```sh
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific
else
    # Linux / other
fi
```

### macOS testing

Docker can't run macOS. For full macOS validation, consider:

- **[Tart](https://github.com/cirruslabs/tart)** — runs macOS VMs natively on Apple Silicon. Create a clean macOS VM, clone the repo, and run `chezmoi init && chezmoi apply` for a true end-to-end test.
- **Separate macOS user account** — create a test user on your machine and init chezmoi from your repo there. Quick and free, but not fully isolated.

Tart can also be integrated into CI (e.g. GitHub Actions with a self-hosted Apple Silicon runner) for automated macOS testing if needed.
