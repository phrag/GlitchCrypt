#!/bin/sh
# GlitchCrypt installer (per user, no root needed).
#   ./install.sh             install glitchcrypt + the idle service
#   ./install.sh --enable    ...and enable/start the service now
#   ./install.sh --uninstall remove both
set -eu

here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

case "${1:-}" in
--uninstall)
    systemctl --user disable --now glitchcrypt.service 2>/dev/null || true
    rm -f "$bin/glitchcrypt" "$unit_dir/glitchcrypt.service"
    systemctl --user daemon-reload
    echo "GlitchCrypt removed."
    exit 0
    ;;
""|--enable) ;;
*)
    echo "usage: $0 [--enable | --uninstall]" >&2
    exit 2
    ;;
esac

missing=""
for cmd in python3 grim tesseract swayidle; do
    command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
for mod in pygame PIL; do
    python3 -c "import $mod" 2>/dev/null || missing="$missing python3-$mod"
done
if [ -n "$missing" ]; then
    echo "Missing:$missing" >&2
    echo "Debian/Ubuntu: sudo apt install python3-pygame python3-pil tesseract-ocr grim swayidle" >&2
    echo "Arch:          sudo pacman -S python-pygame python-pillow tesseract tesseract-data-eng grim swayidle" >&2
    echo "Fedora:        sudo dnf install python3-pygame python3-pillow tesseract grim swayidle" >&2
    exit 1
fi

install -Dm755 "$here/glitchcrypt" "$bin/glitchcrypt"
install -Dm644 "$here/glitchcrypt.service" "$unit_dir/glitchcrypt.service"
systemctl --user daemon-reload
echo "Installed $bin/glitchcrypt and $unit_dir/glitchcrypt.service"

if [ "${1:-}" = --enable ]; then
    systemctl --user enable --now glitchcrypt.service
    echo "Enabled: GlitchCrypt starts after 3 minutes idle."
else
    echo "Try it:   glitchcrypt --seconds 15"
    echo "Enable:   systemctl --user enable --now glitchcrypt.service"
fi
