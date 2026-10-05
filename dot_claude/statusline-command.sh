#!/bin/bash
# Claude Code statusLine.
#
# Renders one line of uniformly-separated cells:
#   ~/.claude │ Opus 4.8 │ ctx ████░░░░░░ 40% │ 5h ██████░░░░ 61% ↻2h13m │ 7d █████████░ 88% ↻3d
#
# ONE separator rule: every cell (identity, ctx, each rate window) is joined by
# a single dim " │ ". Inside a cell, single spaces only. This avoids the
# imperceptible "space-hierarchy" that made gaps ambiguous.
#
# Cell = "<label> <bar> <pct>%[ ↻reset]", left to right, most important first:
#   identity (dir/git/model) · ctx (this conversation) · 5h · 7d (account quota)
#
# Bars: 10 segments (█/░), colored by load — green <50 · yellow 50-80 · red >=80.
# Bar first (fixed 10-wide, anchors the cell); natural-width % trails it. Each
# rate window's reset (↻, bound to its own bar) shows at >=50%. ctx has no reset
# (it clears on a user action, not a clock).
#
# Subscription usage is read straight from the stdin `rate_limits` field (Pro/Max
# only, after the first API response) — no network, no package. Identity uses
# starship when present (cached per session), else a bash fallback.

# --- ANSI helpers -----------------------------------------------------------
R=$'\033[0m'; DIM=$'\033[2m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[1;31m'
CYAN=$'\033[36m'; BLUE=$'\033[34m'

# jq is required to parse stdin; degrade to a bare cwd if it is missing.
if ! command -v jq >/dev/null 2>&1; then
  printf '%s%s%s' "$CYAN" "${PWD##*/}" "$R"
  exit 0
fi

input=$(cat)

# --- single-pass parse ------------------------------------------------------
# One jq call extracts every field, rounds the percentages, and joins them with
# \037 (unit separator). A non-whitespace separator is required: IFS collapses
# empty whitespace-delimited fields, which would shift columns when a middle
# field (e.g. ctx) is absent. \037 preserves empty fields.
IFS=$'\037' read -r session_id dir model ctx h5 h5_rst d7 d7_rst < <(
  jq -r '
    def r: if . == null then "" else (. | round | tostring) end;
    [ (.session_id                              // "")
    , (.workspace.current_dir                   // "")
    , (.model.display_name                      // "")
    , (.context_window.used_percentage          | r)
    , (.rate_limits.five_hour.used_percentage   | r)
    , ((.rate_limits.five_hour.resets_at  // "") | tostring)
    , (.rate_limits.seven_day.used_percentage   | r)
    , ((.rate_limits.seven_day.resets_at // "")  | tostring)
    ] | join("")' <<<"$input" 2>/dev/null
)

# --- cell helpers (fork-free: printf -v into a named var) --------------------
color_for() {  # $1 pct  $2 outvar
  if   [ "$1" -ge 80 ]; then printf -v "$2" '%s' "$RED"
  elif [ "$1" -ge 50 ]; then printf -v "$2" '%s' "$YELLOW"
  else printf -v "$2" '%s' "$GREEN"; fi
}

bar() {  # $1 pct  $2 outvar  -> 10-segment █/░ bar
  local pct=$1 seg=10 fill i out=''
  fill=$(( (pct * seg + 50) / 100 ))
  (( fill > seg )) && fill=$seg
  (( fill < 0 )) && fill=0
  for (( i = 0; i < seg; i++ )); do
    if (( i < fill )); then out+='█'; else out+='░'; fi
  done
  printf -v "$2" '%s' "$out"
}

coarse() {  # $1 epoch  $2 outvar  -> 3d / 2h13m / 2h / 45m / now
  # Days stay coarse; under a day shows hours+minutes so the fast 5h session
  # window keeps useful precision.
  local diff=$(( $1 - now )) h m
  if   (( diff <= 0 ));     then printf -v "$2" 'now'
  elif (( diff >= 86400 )); then printf -v "$2" '%dd' $(( diff / 86400 ))
  elif (( diff >= 3600 )); then
    h=$(( diff / 3600 )); m=$(( (diff % 3600) / 60 ))
    if (( m > 0 )); then printf -v "$2" '%dh%dm' "$h" "$m"
    else printf -v "$2" '%dh' "$h"; fi
  else printf -v "$2" '%dm' $(( diff / 60 )); fi
}

cells=()
push_meter() {  # $1 label  $2 pct  $3 reset-epoch(optional)
  [ -z "$2" ] && return
  local c b rst='' cr seg
  color_for "$2" c
  bar "$2" b
  if [ -n "$3" ] && [ "$2" -ge 50 ]; then coarse "$3" cr; rst=" ${DIM}↻${cr}${R}"; fi
  # <dim>label<r> <color>bar pct%<r>[ <dim>↻reset<r>]  — single spaces only
  printf -v seg '%s%s%s %s%s %d%%%s%s' "$DIM" "$1" "$R" "$c" "$b" "$2" "$R" "$rst"
  cells+=("$seg")
}

# --- identity (starship dir/git, cached per session ~3s; model added fresh) --
render_identity() {  # prints dir/git to stdout; run inside the target cwd
  if command -v starship >/dev/null 2>&1; then
    STARSHIP_CONFIG="$HOME/.claude/starship-statusline.toml" STARSHIP_SHELL=sh \
      starship prompt 2>/dev/null
  else
    printf '%s%s%s' "$CYAN" "${dir##*/}" "$R"
    local br
    br=$(git -c core.fsmonitor=false --no-optional-locks branch --show-current 2>/dev/null)
    [ -n "$br" ] && printf ' %s %s%s' "$GREEN" "$br" "$R"
  fi
}

now=$(date +%s)   # single clock read, reused by coarse() and the cache check
idcache="${TMPDIR:-/tmp}/claude-sl-${session_id:-none}"
mtime=0
[ -f "$idcache" ] && mtime=$(stat -f %m "$idcache" 2>/dev/null || echo 0)
if [ -z "$session_id" ] || [ ! -f "$idcache" ] || (( now - mtime >= 3 )); then
  # cd failure is non-fatal: identity then renders for the current dir.
  ( [ -n "$dir" ] && cd "$dir" 2>/dev/null || :; render_identity ) >"$idcache" 2>/dev/null
fi
ident=$(<"$idcache")
ident="${ident% }"   # starship leaves one trailing space

# --- assemble: uniform " │ " between every non-empty cell -------------------
# Cells: <dir git> │ <model> │ ctx │ 5h │ 7d. dir+git stay space-joined inside
# one cell (the branch is an attribute of that directory); model is its own cell.
[ -n "$ident" ] && cells+=("$ident")
[ -n "$model" ] && cells+=("${BLUE}${model}${R}")
push_meter 'ctx' "$ctx"
push_meter '5h'  "$h5" "$h5_rst"
push_meter '7d'  "$d7" "$d7_rst"

out=''
for c in "${cells[@]}"; do
  out="${out:+$out ${DIM}│${R} }$c"
done
printf '%s' "$out"
