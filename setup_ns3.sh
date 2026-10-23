#!/usr/bin/env bash
#
# Prepare the ns-3 submodule for the experiment: link the nr submodule into
# ns-3's contrib/ and, with --build, configure and build the optimized tree.
#
# ns-3 discovers modules under contrib/, so nr has to appear at ns-3/contrib/nr.
# It is a submodule beside ns-3 rather than inside it, so that every pin lives in
# this repository and moving the nr pin needs no commit in the ns-3 fork. The
# link is listed in ns-3's .git/info/exclude so the ns-3 checkout stays clean.
#
# NS3_PYTHON picks the interpreter for the ns3 wrapper (default python3); the
# ns-3.44 wrapper fails under Python 3.14's argparse, so point it at an older
# one there, e.g. NS3_PYTHON=/usr/bin/python3.10.

set -euo pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
cd "$SCRIPT_DIR"

build=0
case "${1:-}" in
  "")      ;;
  --build) build=1 ;;
  -h|--help)
    printf 'Usage: %s [--build]\n\n  --build   also run ./ns3 configure -d optimized --enable-examples && ./ns3 build\n' "${0##*/}"
    exit 0 ;;
  *) printf 'error: unknown argument: %s (try --help)\n' "$1" >&2; exit 1 ;;
esac

git submodule update --init ns-3 nr

link=ns-3/contrib/nr
if [[ -L "$link" ]]; then
  :
elif [[ -e "$link" ]]; then
  printf 'error: %s exists and is not a link; move it away first\n' "$link" >&2
  exit 1
else
  ln -s ../../nr "$link"
fi

exclude=$(git -C ns-3 rev-parse --git-path info/exclude)
mkdir -p "$(dirname -- "$exclude")"
grep -qxF '/contrib/nr' "$exclude" 2>/dev/null || echo '/contrib/nr' >> "$exclude"

printf 'ns-3/contrib/nr -> nr (%s)\n' "$(git -C nr rev-parse --short=9 HEAD)"

if [[ $build -eq 1 ]]; then
  cd ns-3
  py=${NS3_PYTHON:-python3}
  "$py" ./ns3 configure -d optimized --enable-examples
  "$py" ./ns3 build
fi
