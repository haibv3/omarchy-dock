#!/usr/bin/env bash
# Rebuild + reinstall omarchy-dock (plugin mode).
#   ./rebuild.sh                 lint, validate, install, restart shell
#   ./rebuild.sh --no-restart    skip 'omarchy restart shell' (changes stay stale)
#   ./rebuild.sh --no-lint       skip qmllint/manifest checks
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QMLLINT=/usr/lib/qt6/bin/qmllint
DO_LINT=1 DO_RESTART=1
for arg in "$@"; do
    case "$arg" in
        --no-lint) DO_LINT=0 ;;
        --no-restart) DO_RESTART=0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

if (( DO_LINT )); then
    echo "==> qmllint"
    # qmllint emits many 'unqualified access' warnings inherent to the DI
    # pattern — only 'Error:' lines are defects.
    lint_out="$("$QMLLINT" $(find "$SRC" -name '*.qml' -not -path '*/.git/*') 2>&1)" || true
    echo "$lint_out"
    if grep -q 'Error:' <<<"$lint_out"; then
        echo "qmllint reported errors — aborting." >&2
        exit 1
    fi

    echo "==> omarchy plugin validate"
    omarchy plugin validate "$SRC"
fi

# A standalone instance sharing the same config would show a second dock.
if pgrep -f "quickshell -p $SRC" >/dev/null; then
    echo "WARNING: standalone 'quickshell -p $SRC' is running; stop it with:" >&2
    echo "  quickshell ipc -p $SRC call dock quit" >&2
fi

echo "==> install.sh --plugin"
"$SRC/install.sh" --plugin

if (( DO_RESTART )); then
    # keepLoaded: true — plugin code is a snapshot; restart is REQUIRED.
    echo "==> omarchy restart shell"
    omarchy restart shell
    echo "Done. Shell restarted with the new plugin code."
else
    echo "Done. Run 'omarchy restart shell' to load the new plugin code."
fi
