#!/usr/bin/env bash
set -e

FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR" --depth 1
fi

if ! grep -q 'flutter/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bashrc"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --enable-web --no-analytics
flutter precache --web
flutter doctor -v
