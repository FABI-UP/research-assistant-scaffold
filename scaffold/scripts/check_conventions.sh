#!/usr/bin/env sh
# Static checks that turn written conventions into enforced ones.
# Run before every commit. Nothing here needs anything installed.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
ok()  { printf 'OK    %s\n' "$*"; }
bad() { printf 'FAIL  %s\n' "$*"; fail=1; }

# --- 1. every step declares its I/O -----------------------------------------
for f in "$ROOT"/src/steps/*; do
  [ -f "$f" ] || continue
  n=$(basename "$f")
  for k in INPUTS OUTPUTS PURPOSE; do
    grep -q "^# *$k:" "$f" || bad "$n: missing '# $k:' header"
  done
  # A glob over a directory hides what a step consumed.
  if grep -E '^# *(INPUTS|OUTPUTS):' "$f" | grep -qE '\*|\?'; then
    bad "$n: declared I/O contains a glob — name exact paths"
  fi
done
[ "$fail" = "0" ] && ok "every step declares exact INPUTS, OUTPUTS and PURPOSE"

# --- 2. portability: no bashisms in /bin/sh scripts -------------------------
# The machine you write on is not the machine it runs on. This cannot be caught
# by testing where you wrote it, so it is a static check.
port=0
# Note the exclusions: [[:alpha:]] is a POSIX character class, not a [[ test, and
# awk programs embedded in a shell script have their own 'function' keyword.
BASHISM='\[\[[^:]|^[[:space:]]*local[[:space:]]|<<<|declare[[:space:]]+-|readarray|mapfile|\$\{[A-Za-z_]+\^\^|\$\{[A-Za-z_]+,,|echo[[:space:]]+-e'
for f in $(find "$ROOT/src" "$ROOT/scripts" "$ROOT/tests" -name '*.sh' 2>/dev/null); do
  head -1 "$f" | grep -q 'env sh\|/bin/sh' || continue
  n=${f#"$ROOT"/}
  case "$n" in */check_conventions.sh) continue ;; esac
  if grep -nE "$BASHISM" "$f"; then
    bad "$n: bashism in a POSIX sh script (above)"; port=1
  fi
done
[ "$port" = "0" ] && ok "no bashisms in POSIX sh scripts"

# --- 3. nothing personal, local or secret in tracked files ------------------
# The kit this came from found live .env files, a collaborator's username and a
# personal email in repositories that were about to be shared.
leak=0
pat='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}'
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  list=$(git -C "$ROOT" ls-files)
else
  list=$(cd "$ROOT" && find . -type f -not -path './.git/*' -not -path './results/*' -not -path './logs/*')
fi
for f in $list; do
  case "$f" in *.example|*/check_conventions.sh) continue ;; esac
  [ -f "$ROOT/$f" ] || continue
  if grep -nIE "$pat" "$ROOT/$f" >/dev/null 2>&1; then
    bad "$f: contains an email address, home path or credential-shaped string"
    leak=1
  fi
done
[ "$leak" = "0" ] && ok "no emails, home paths or credential-shaped strings in tracked files"

# --- 4. .env is ignored and not tracked -------------------------------------
if [ -f "$ROOT/.env" ]; then
  if command -v git >/dev/null 2>&1 && git -C "$ROOT" ls-files --error-unmatch .env >/dev/null 2>&1; then
    bad ".env is TRACKED. Remove it from the index and rotate anything it held."
  else
    ok ".env exists locally and is not tracked"
  fi
else
  ok "no .env present"
fi

# --- 5. no placeholders left in a configured repository ---------------------
if [ ! -f "$ROOT/.scaffold-unconfigured" ]; then
  if grep -rl '{{' "$ROOT" --exclude-dir=.git --exclude-dir=results --exclude-dir=logs \
       --exclude='check_conventions.sh' --exclude-dir=_template 2>/dev/null | grep -q .; then
    grep -rl '{{' "$ROOT" --exclude-dir=.git --exclude-dir=results --exclude-dir=logs \
      --exclude='check_conventions.sh' --exclude-dir=_template 2>/dev/null | sed 's|^|      |'
    bad "unfilled {{PLACEHOLDERS}} remain in the files above"
  else
    ok "no unfilled placeholders"
  fi
fi

[ "$fail" = "0" ] && { printf '\nconventions OK\n'; exit 0; }
printf '\nconvention checks failed\n'; exit 1
