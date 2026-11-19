#!/bin/sh
# GlitchCrypt installer (per user, no root needed).
#   ./install.sh             install the screensaver, settings app and idle service
#   ./install.sh --enable    ...and turn the idle service on now
#   ./install.sh --uninstall remove everything (keeps ~/.config/glitchcrypt)
set -eu

here=$(cd "$(dirname "$0")" && pwd)
bin="$HOME/.local/bin"
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
desktop=app.glitchcrypt.Settings.desktop

case "${1:-}" in
--uninstall)
    systemctl --user disable --now glitchcrypt.service 2>/dev/null || true
    rm -f "$bin/glitchcrypt" "$bin/glitchcrypt-settings" \
          "$unit_dir/glitchcrypt.service" "$apps/$desktop"
    systemctl --user daemon-reload
    echo "GlitchCrypt removed. Your settings are still in ~/.config/glitchcrypt/."
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
    PYGAME_HIDE_SUPPORT_PROMPT=1 python3 -c "import $mod" >/dev/null 2>&1 \
        || missing="$missing python3-$mod"
done
if [ -n "$missing" ]; then
    echo "Missing:$missing" >&2
    echo "Debian/Ubuntu: sudo apt install python3-pygame python3-pil tesseract-ocr grim swayidle" >&2
    echo "Arch:          sudo pacman -S python-pygame python-pillow tesseract tesseract-data-eng grim swayidle" >&2
    echo "Fedora:        sudo dnf install python3-pygame python3-pillow tesseract grim swayidle" >&2
    exit 1
fi
if ! python3 -c 'import gi; gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")' 2>/dev/null; then
    echo "Note: the settings app needs GTK 4 + libadwaita for Python" >&2
    echo "      (Debian/Ubuntu: python3-gi gir1.2-gtk-4.0 gir1.2-adw-1)." >&2
    echo "      The screensaver itself works without it." >&2
fi

install -Dm755 "$here/glitchcrypt" "$bin/glitchcrypt"
install -Dm755 "$here/glitchcrypt-settings" "$bin/glitchcrypt-settings"
install -Dm644 "$here/glitchcrypt.service" "$unit_dir/glitchcrypt.service"
mkdir -p "$apps"
sed "s|@BINDIR@|$bin|" "$here/$desktop" > "$apps/$desktop"
systemctl --user daemon-reload
command -v update-desktop-database >/dev/null && update-desktop-database "$apps" 2>/dev/null || true
echo "Installed glitchcrypt, glitchcrypt-settings and glitchcrypt.service."

if [ "${1:-}" = --enable ]; then
    systemctl --user enable --now glitchcrypt.service
    echo "Enabled: GlitchCrypt starts when idle (3 minutes by default)."
fi
echo "Open \"GlitchCrypt\" from your app launcher (or run glitchcrypt-settings) to configure it."
