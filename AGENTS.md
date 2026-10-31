# AGENTS.md

This file provides guidance to AI agents working with code in this repository.

<important-instruction>
- No destructive action unless have backup and confirmed
</important-instruction>

## What this repo is

A [chezmoi](https://www.chezmoi.io/) dotfiles repo.
Chezmoi deploys managed files from this source directory (`~/.local/share/chezmoi`) into the home directory.
Files here are not the live copies — `chezmoi apply` copies them out.

## Day-to-day commands

```sh
chezmoi status         # list managed files that differ from source
chezmoi diff           # preview what apply would change
chezmoi apply -v       # deploy managed files to ~
chezmoi add ~/.foo     # start managing a new file
chezmoi edit ~/.zshrc  # edit source and apply in one step
chezmoi cd             # open shell in source dir
```

## File naming conventions

- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `private_` → file mode 600
- `.tmpl` suffix → Go template, processed before deployment (main use: OS conditionals).
  Verify rendered output with `chezmoi diff` before applying.
- `run_once_` prefix → script runs only once (tracked by chezmoi)
- Files in `dot_config/` → `~/.config/`

## Machine-local lines

Managed shell files source unmanaged `.local` files.
Put auto-injected or secret lines there, not in the managed file:

- `~/.zshrc.local` (deno, LM Studio, etc.)
- `~/.zprofile.local` (OrbStack, rustup)
- `~/.secrets.local` (secrets)
