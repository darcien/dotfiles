# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<important-instruction>
- No destructive action unless have backup and confirmed
</important-instruction>

## What this repo is

A [chezmoi](https://www.chezmoi.io/) dotfiles repo.
Chezmoi deploys managed files from this source directory (`~/.local/share/chezmoi`) into the home directory.
Files here are **not** the live copies — `chezmoi apply` copies them out.

## Key commands

```sh
chezmoi apply -v       # deploy managed files to ~
chezmoi diff           # preview what apply would change
chezmoi status         # list managed files that differ from source
chezmoi add ~/.foo     # start managing a new file
chezmoi edit ~/.zshrc  # edit source and apply in one step
chezmoi cd             # open shell in source dir
```

Adding a new Homebrew package: edit `Brewfile`, then run:
```sh
brew bundle install --file ~/.local/share/chezmoi/Brewfile
```

## File naming conventions

Chezmoi uses special prefixes/suffixes to map source files to destinations:

- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `.tmpl` suffix → file is a Go template, processed before deployment
- `run_once_` prefix → script runs only once (tracked by chezmoi)
- Files in `dot_config/` → `~/.config/`

## Machine-local overrides pattern

Tools like OrbStack, LM Studio, deno, and rustup auto-inject lines into shell files.
Since `chezmoi apply` overwrites those files, the managed shell configs source unmanaged `.local` counterparts:

- `~/.zshrc` sources `~/.zshrc.local`
- `~/.zprofile` sources `~/.zprofile.local`
- `~/.secrets.local` for secrets

Any auto-injected or sensitive config belongs in the `.local` files, not in the chezmoi-managed source.

## What is and is not managed

Managed by chezmoi: shell configs (zsh, bash, profile), `.gitconfig`, `lazygit/config.yml`, Homebrew install script.

Not managed (in `.chezmoiignore`): `Brewfile`, `README.md`, `com.googlecode.iterm2.plist`.

## Template files

Any `.tmpl` file is processed as a Go template before deployment.
The main use here is OS conditionals — e.g. different path on macOS `{{ if eq .chezmoi.os "darwin" }}`.
Use `chezmoi diff` to verify the rendered output before applying.
