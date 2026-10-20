#!/usr/bin/env sh
# Exercises scaffold-library/scripts/check_library.sh against small fixture collections.
# Runs from the kit root with nothing installed but a POSIX shell and the usual tools.
set -eu
KIT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0; fail=0
ok() { printf '  PASS  %s\n' "$*"; pass=$((pass+1)); }
no() { printf '  FAIL  %s\n' "$*"; fail=$((fail+1)); }

fresh() {
  rm -rf "$WORK/lib" && cp -R "$KIT/scaffold-library" "$WORK/lib"
  mkdir -p "$WORK/lib/collection/theme"
}
item() { printf '%s\n' "$1" > "$WORK/lib/collection/theme/$1"; }
totals() {  # totals DISTINCT FILES DATE — rewrite the Totals and Last verified lines
  sed -e "s/^\*\*Totals:\*\*.*/**Totals:** $1 distinct items | $2 files | 0 repeat copies | 0 unidentified/" \
      -e "s/^\*\*Last verified:\*\* [^ ]*/**Last verified:** $3/" \
      "$WORK/lib/INDEX.md" > "$WORK/INDEX.tmp" && mv "$WORK/INDEX.tmp" "$WORK/lib/INDEX.md"
}
run() { sh "$WORK/lib/scripts/check_library.sh" 2>&1; }
today=$(date -u +%Y-%m-%d)

printf 'library test\n'
printf -- '--- 1. an empty collection passes ---\n'
fresh
run >/dev/null && ok "fresh library passes" || no "fresh library fails"

printf -- '--- 2. names ---\n'
fresh
item Smith_2024_thermal_limits.pdf; item van_der_Merwe_2021_field_survey.pdf; item Lee-Park_2019_review.pdf
totals 3 3 "$today"
run >/dev/null && ok "conventional and multi-part surnames pass" || no "valid names were rejected"
item download_8812.pdf; totals 4 4 "$today"
run | grep -q 'download_8812.pdf' && ok "a non-conforming name is reported" || no "a non-conforming name was not reported"

printf -- '--- 3. totals ---\n'
fresh
item Smith_2024_a.pdf; cp "$WORK/lib/collection/theme/Smith_2024_a.pdf" "$WORK/lib/collection/theme/Smith_2024_a_b.pdf"
totals 1 2 "$today"
run | grep -q 'file total (2) matches' && ok "the files figure is compared, not the distinct-items figure" \
  || no "a correct files total with a deliberate repeat was flagged"
totals 1 3 "$today"
run >/dev/null && no "a wrong files total passed" || ok "a wrong files total fails"

printf -- '--- 4. loose items and intake ---\n'
fresh
printf 'x\n' > "$WORK/lib/collection/Loose_2020_item.pdf"; totals 1 1 "$today"
run | grep -q 'sitting in the collection root' && ok "a loose item in the collection root is reported" || no "a loose item was not reported"
fresh
printf 'x\n' > "$WORK/lib/intake/new.pdf"; totals 0 0 "$today"
run >/dev/null && no "an item left in intake passed" || ok "an item left in intake fails"

printf -- '--- 5. refresh interval ---\n'
fresh; totals 0 0 2000-01-01
run | grep -q 'maintenance pass is due' && ok "an overdue refresh is reported" || no "an overdue refresh was not reported"
fresh; totals 0 0 "$today"
run | grep -q 'verified 0 days ago' && ok "a current verification date is recognised" || no "days since verification not computed"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = "0" ] || exit 1
