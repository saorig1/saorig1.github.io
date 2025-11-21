#!/usr/bin/env bash
# Usage:
#   ./update-refs.sh --dry-run   # only list matches
#   ./update-refs.sh             # perform replacements (creates .bak for each changed file)
#
# Reads mapping.tsv (original<TAB>new) and replaces all occurrences of original
# path strings with the new filename in text files (html, css, js, php, md, etc).
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

MAPFILE="mapping.tsv"
if [[ ! -f "$MAPFILE" ]]; then
  echo "mapping.tsv not found. Run ./generate-mapping.sh first."
  exit 1
fi

# files/dirs to exclude from search
EXCLUDE_ARGS=(--exclude-dir=.git --exclude=mapping.tsv --exclude=generate-mapping.sh --exclude=update-refs.sh --exclude=apply-moves.sh)

# iterate mappings
while IFS=$'\t' read -r orig new; do
  matches=$(grep -RIl "${EXCLUDE_ARGS[@]}" -e "$orig" . || true)
  if [[ -z "$matches" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      continue
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    if [[ -n "$matches" ]]; then
      echo "Would replace occurrences of:"
      echo "  $orig -> $new"
      echo "  In files:"
      echo "$matches" | sed 's/^/    /'
      echo
    fi
  else
    if [[ -n "$matches" ]]; then
      echo "Replacing: $orig -> $new"
      while IFS= read -r f; do
        # Use perl with \Q...\E to escape any special chars in $orig
        perl -0777 -pe "s/\Q$orig\E/$new/g" -i.bak "$f"
        echo "  updated $f (backup: $f.bak)"
      done <<< "$matches"
    fi
  fi
done < "$MAPFILE"

echo "Done. (dry-run=$DRY_RUN)"