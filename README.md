# dotfiles

Managed by [chezmoi](https://www.chezmoi.io/).

## new machine

```sh
brew install chezmoi
chezmoi init --repo <git-clone-url>
chezmoi apply
```

Linux: install build-essential / gcc before `chezmoi apply` (brew needs it).
The `run_once` script installs Homebrew and runs `brew bundle install` on first apply.

## daily use

```sh
chezmoi apply -v       # deploy managed files
chezmoi diff           # preview what apply would change
chezmoi status         # list managed files that differ
chezmoi add ~/.foo     # start managing a new file
chezmoi edit ~/.zshrc  # edit source, then apply
chezmoi cd             # open shell in source dir
```

## machine-local overrides

Some tools (OrbStack, LM Studio, deno, rustup) auto-inject lines into shell
files. `chezmoi apply` overwrites those, so they'd disappear.

Each managed shell file sources a `.local` counterpart that chezmoi ignores:

- `~/.zshrc.local`
- `~/.zprofile.local`
- `~/.secrets.local` (same pattern, already existed)

After first `chezmoi apply` on a new machine, move any auto-injected lines
into the matching `.local` file. chezmoi stays clean, the tools keep working.

## optional tools

Not in Brewfile. Install as needed — each one self-injects into shell files,
so move its lines into `~/.zshrc.local` after installing.

- [Rust](https://www.rust-lang.org) — `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` (rustup adds `.cargo/env` to every profile it finds)
- [Deno](https://deno.land) — `curl -fsSL https://deno.land/install.sh | sh` (adds env source + completions)
- [asdf](https://asdf-vm.com) — `brew install asdf` (adds shims PATH)

## adding packages

Edit Brewfile in source dir, then:

```sh
brew bundle install --file ~/.local/share/chezmoi/Brewfile
```

## macOS apps (manual)

[Tailscale](https://tailscale.com) — not in Brewfile. Its `.pkg` installer needs
interactive `sudo`, which breaks `brew bundle install` when run non-interactively.
Install manually: `brew install --cask tailscale`

[OrbStack](https://orbstack.dev) — install from website. Self-injects into
`~/.zprofile`, so move its line into `~/.zprofile.local` after installing.

[LM Studio](https://lmstudio.ai) — install from website. Self-injects a PATH
entry into `~/.zshrc`, so move it into `~/.zshrc.local` after installing.

[iTerm2](https://iterm2.com) — installed via Brewfile, but its config is not
managed by chezmoi. `com.googlecode.iterm2.plist` is kept in this repo as a
static backup. Copy manually to `~/Library/Preferences/` if restoring.
