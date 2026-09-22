#!/bin/bash
set -e

# Zen browser — official Linux tarball into ~/zen (user-writable, so the
# autoconfig symlinks in install.sh need no sudo, and Zen can self-update).
ZEN_HOME="${ZEN_HOME:-$HOME/zen}"

if [ -x "$ZEN_HOME/zen" ]; then
  echo "zen already installed: $ZEN_HOME"
  exit 0
fi

if [ "$(uname -s)" != "Linux" ]; then
  echo "Skipping zen (tarball install is Linux-only; on macOS: brew install --cask zen)"
  exit 0
fi

case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  aarch64|arm64) arch=aarch64 ;;
  *) echo "No zen build for $(uname -m)"; exit 1 ;;
esac

url="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-$arch.tar.xz"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $url"
if command -v curl &>/dev/null; then
  curl -fL --progress-bar "$url" -o "$tmp/zen.tar.xz"
elif command -v wget &>/dev/null; then
  wget -q --show-progress "$url" -O "$tmp/zen.tar.xz"
else
  echo "Need curl or wget to install zen"
  exit 1
fi

# Tarball's top-level dir is zen/
tar -xJf "$tmp/zen.tar.xz" -C "$tmp"
mkdir -p "$(dirname "$ZEN_HOME")"
mv "$tmp/zen" "$ZEN_HOME"

mkdir -p ~/.local/bin ~/.local/share/applications
ln -sf "$ZEN_HOME/zen" ~/.local/bin/zen

cat > ~/.local/share/applications/zen.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Zen Browser
Comment=A Firefox-based privacy browser
Exec=$ZEN_HOME/zen %u
Icon=$ZEN_HOME/browser/chrome/icons/default/default128.png
Terminal=false
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
Categories=Network;WebBrowser;
Keywords=web;browser;internet;
EOF
command -v update-desktop-database &>/dev/null && update-desktop-database ~/.local/share/applications 2>/dev/null || true

echo "zen installed: $ZEN_HOME (launcher: ~/.local/bin/zen, desktop entry added)"
