set -euo pipefail

# T3 preserves its managed tunnel when this fresh restart marker exists.
marker="${T3CODE_HOME:-$HOME/.t3}/runtime/desktop-update-restart"
touch "$marker"
trap 'rm -f "$marker"' EXIT

if systemctl cat t3code.service >/dev/null 2>&1; then
  sudo systemctl restart t3code.service
else
  systemctl --user restart t3code.service
fi
