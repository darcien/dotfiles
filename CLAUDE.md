# CLAUDE.md

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

## Volatile configs (live vs managed drift)

Some configs are rewritten by tools at runtime, so tracking them verbatim means constant
drift and `chezmoi apply` clobbering live changes. Two patterns handle this:

1. Sourced `.local` counterpart — for configs where lines can be split out.
Managed shell files source unmanaged local files; auto-injected or sensitive lines go there:

- `~/.zshrc` sources `~/.zshrc.local` (deno, LM Studio, etc.)
- `~/.zprofile` sources `~/.zprofile.local` (OrbStack, rustup)
- `~/.secrets.local` for secrets

2. `modify_` merge template — for single-file configs (e.g. JSON) the tool rewrites in place.
The source holds only curated keys; a `chezmoi:modify-template` deep-merges them over the live
file on apply. Curated keys win, untracked keys pass through untouched.

Current instance: `~/.claude/settings.json` (Claude Code live-writes keys like `model`):

- `dot_claude/settings.managed.json` — curated keys only. In `.chezmoiignore`, never deployed itself.
- `dot_claude/modify_private_settings.json` — the merge template (`mergeOverwrite`, output is
  sorted pretty JSON).

Ops for a `modify_` target:

- Change enforced config: edit the managed JSON, `chezmoi apply`.
- Adopt a live value into managed: copy the key into the managed JSON manually (or with jq).
- `chezmoi re-add` does not work on these targets.
- `chezmoi diff` empty = no drift; nonempty = apply (enforce) or promote (adopt), your call.

## rtk (Rust Token Killer)

`rtk init` injects into `~/.claude/CLAUDE.md` (`@RTK.md` import), `~/.claude/RTK.md`, and
`~/.claude/settings.json` (PreToolUse hook). All three are captured in source, so a fresh machine
needs no `rtk init`. Only re-run it when upgrading rtk changes its output, then recapture:

```sh
rtk init -g --auto-patch   # non-interactive; rewrites the live ~/.claude files
chezmoi re-add ~/.claude/CLAUDE.md ~/.claude/RTK.md
# settings.json is a modify_ target: copy the changed hook from ~/.claude/settings.json
# into dot_claude/settings.managed.json by hand, then chezmoi apply
```
