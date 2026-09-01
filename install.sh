#!/usr/bin/env bash
# ALBots one-line installer (public loader).
# Скачивает приватный установщик из avdivo/bot_platform и запускает его.
#
# Использование (ключ нужен один раз, read-only PAT на чтение приватного репо):
#   curl -fsSL https://raw.githubusercontent.com/avdivo/albots-install/main/install.sh \
#     | GITHUB_TOKEN=<ключ> bash -s -- local
#
# Аргументы — те же, что у deploy/install.sh: local | user@host[:port] [dir] [port]
#   local        — установка на эту машину (каталог ~/albots, консоль 127.0.0.1:8003)
#   user@host    — установка по SSH на сервер (каталог /opt/albots)
# Секреты установки — единый файл <каталог установки>/install-secrets.env
# (создаётся установщиком при первом запуске), из GitHub не приходят.
# Повторный запуск = обновление.
set -euo pipefail

REPO="${ALBOTS_REPO:-avdivo/bot_platform}"
BRANCH="${ALBOTS_BRANCH:-main}"

# Ключ для скачивания: env → новый файл секретов (~/albots) → старый (~/.albots)
if [[ -z "${GITHUB_TOKEN:-}" && -f "$HOME/albots/install-secrets.env" ]]; then
  GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "$HOME/albots/install-secrets.env" 2>/dev/null || true)"
fi
if [[ -z "${GITHUB_TOKEN:-}" && -f "$HOME/.albots/install-secrets.env" ]]; then
  GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "$HOME/.albots/install-secrets.env" 2>/dev/null || true)"
fi
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Нет GITHUB_TOKEN: передай ключ в команде — GITHUB_TOKEN=<ключ> bash -s -- local" >&2
  echo "(нужен read-only PAT с доступом к приватному репо $REPO)" >&2
  exit 1
fi

TMP="$(mktemp -d /tmp/albots-install-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "[albots-install] Загружаю установщик ($REPO@$BRANCH)…"
curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  "https://codeload.github.com/$REPO/tar.gz/$BRANCH" -o "$TMP/repo.tar.gz"
mkdir -p "$TMP/src"
tar -xzf "$TMP/repo.tar.gz" -C "$TMP/src"
SRC="$(find "$TMP/src" -mindepth 1 -maxdepth 1 -type d | head -1)"

bash "$SRC/deploy/install.sh" "$@"
