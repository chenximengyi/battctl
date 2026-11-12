#!/bin/bash
# Install the native-only CLI; no battery-control daemon is installed.
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
[[ $# == 0 ]] || { echo 'Usage: install.sh' >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST='/Library/Application Support/battctl'
[[ -x "$ROOT/build/battctl" ]] || { echo 'Run make first.' >&2; exit 1; }
[[ ! -L "$DEST" ]] || { echo 'Refusing symlink install directory.' >&2; exit 1; }
if launchctl print system/com.chenxi.battctl >/dev/null 2>&1; then
 echo 'A legacy SMC daemon is installed. Stop and remove it before installing the native CLI.' >&2; exit 1
fi
LINK=/usr/local/bin/battctl
if [[ -e "$LINK" || -L "$LINK" ]]; then
 [[ -L "$LINK" && $(readlink "$LINK") == "$DEST/battctl" ]] || { echo 'Existing /usr/local/bin/battctl belongs to another installation.' >&2; exit 1; }
fi
/bin/bash "$ROOT/scripts/cleanup-experimental.sh"
# Carry over a target saved under a previous bundle identifier before installing.
TARGET_PLIST=/Library/Preferences/com.chenxi.battctl.plist
if [[ ! -e "$TARGET_PLIST" ]]; then
 for legacy in /Library/Preferences/com.*.battctl.plist; do
  [[ -f "$legacy" && ! -L "$legacy" ]] || continue
  install -o root -g wheel -m 644 "$legacy" "$TARGET_PLIST"
  echo "Copied a previously saved target from $legacy. Re-run battctl verify to confirm it."
  break
 done
fi
install -d -o root -g wheel -m 755 "$DEST"
install -o root -g wheel -m 755 "$ROOT/build/battctl" "$DEST/battctl.new"
mv -f "$DEST/battctl.new" "$DEST/battctl"
[[ -d /usr/local/bin ]] || install -d -o root -g wheel -m 755 /usr/local/bin
[[ -L "$LINK" ]] || ln -s "$DEST/battctl" "$LINK"
echo 'Installed /usr/local/bin/battctl. Battery settings unchanged. Check: battctl verify'
