if [ -e .secrets.local ]; then
  source .secrets.local
fi

# Prefer ls deluxe over regular ls
# https://github.com/Peltoche/lsd
alias ls='lsd'
alias lg='lazygit'
alias ld='lazydocker'

# Regular VS Code no longer crashing,
# disabling insiders for now.
# alias codei='code-insiders'
# alias code='code-insiders'

# navigation aliases
alias p="cd ~/projects/"

alias czsh="code $HOME/.zshrc"
# reload shell conifg
alias reload="exec -l $SHELL"

# Path to global binary installed by yarn
export PATH="$(yarn global bin):$PATH"

# PATH for deno bin
# Added 2022-05-13
export DENO_INSTALL="/Users/darcien/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# From Android Studio default SDK
export JAVA_HOME="/Applications/Android Studio.app/Contents/jre/Contents/Home"

# Android SDK path
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/emulator

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Tailscale - https://tailscale.com/kb/1080/cli/#using-the-cli
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Preferred browser
# Only works for expo start:web
# For gh pr create --web, it's failing
# Other variant using path to /Applications also doesnt work for gh
# export BROWSER="Arc"

# fnm
# eval "$(fnm env)"
# switch to use-on-cd on 2024-01-21 so node version is always correct on different project
eval "$(fnm env --use-on-cd)"

# load rbenv for ruby automatically
eval "$(rbenv init -)"

# Using starship prompt
# https://github.com/starship/starship
eval "$(starship init zsh)"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='micro'
else
  export EDITOR='code --wait'
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/darcien/miniconda/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/Users/darcien/miniconda/etc/profile.d/conda.sh" ]; then
    . "/Users/darcien/miniconda/etc/profile.d/conda.sh"
  else
    export PATH="/Users/darcien/miniconda/bin:$PATH"
  fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Zinit disabled for now, no use other than https://github.com/joshskidmore/zsh-fzf-history-search
# which got replaced by mcfly
# # From zinit install script
# # Zinit is a flexible and fast Zshell plugin manager
# # https://github.com/zdharma-continuum/zinit
# ### Added by Zinit's installer
# if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
#     print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
#     command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
#     command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
#         print -P "%F{33} %F{34}Installation successful.%f%b" || \
#         print -P "%F{160} The clone has failed.%f%b"
# fi

# source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
# autoload -Uz _zinit
# (( ${+_comps} )) && _comps[zinit]=_zinit

# # Load a few important annexes, without Turbo
# # (this is currently required for annexes)
# zinit light-mode for \
#     zdharma-continuum/zinit-annex-as-monitor \
#     zdharma-continuum/zinit-annex-bin-gem-node \
#     zdharma-continuum/zinit-annex-patch-dl \
#     zdharma-continuum/zinit-annex-rust

# ### End of Zinit's installer chunk

# fix `zsh: no matches found` error
# when running command with `^`
# e.g. git reset HEAD^
# https://github.com/ohmyzsh/ohmyzsh/issues/449#issuecomment-6973326
# Happening since switching from omz to pure setup
setopt NO_NOMATCH

# Remove command lines from the history list when the first character on the line is a space, or when one of the expanded aliases contains a leading space.
# Only normal aliases (not global or suffix aliases) have this behaviour.
# Note that the command lingers in the internal history until the next command is entered before it vanishes, allowing you to briefly reuse or edit the line.
# If you want to make it vanish right away without entering another command, type a space and press return.
setopt HIST_IGNORE_SPACE

# Cycle through history based on characters already typed on the line
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Needed for completion
autoload -Uz compinit
compinit

# Make selection visible and allow using arrow keys to select
# Need compinit to works
zstyle ':completion:*' menu select

# better ctrl-r history
# https://github.com/cantino/mcfly
eval "$(mcfly init zsh)"
