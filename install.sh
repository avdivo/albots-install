#!/usr/bin/env bash
# ALBots one-line installer (public loader).
# Скачивает приватный установщик из avdivo/bot_platform и запускает его.
#
# Использование (ключ нужен один раз, read-only PAT на чтение приватного репо):
#   cd <папка>                 # сюда кладём install-secrets.env
#   curl -fsSL https://raw.githubusercontent.com/avdivo/albots-install/main/install.sh | bash
#
# Папка запуска = «корень развёртывания»: в ней лежит install-secrets.env, а
# установка идёт в её подкаталог albots/ (albots1, …). Одинаково на сервере и на
# локальной машине. GITHUB_TOKEN берётся из окружения или из ./install-secrets.env.
# Аргументы пробрасываются в deploy/install.sh:
#   --clean — переставить заново;  --new — отдельная копия рядом.
set -euo pipefail

REPO="${ALBOTS_REPO:-avdivo/bot_platform}"
BRANCH="${ALBOTS_BRANCH:-main}"

# Ключ для скачивания: окружение → ./install-secrets.env → старые места.
if [[ -z "${GITHUB_TOKEN:-}" && -f "$PWD/install-secrets.env" ]]; then
  GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "$PWD/install-secrets.env" 2>/dev/null | tr -d '"' || true)"
fi
if [[ -z "${GITHUB_TOKEN:-}" && -f "$HOME/albots/install-secrets.env" ]]; then
  GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "$HOME/albots/install-secrets.env" 2>/dev/null | tr -d '"' || true)"
fi
if [[ -z "${GITHUB_TOKEN:-}" && -f "$HOME/.albots/install-secrets.env" ]]; then
  GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "$HOME/.albots/install-secrets.env" 2>/dev/null | tr -d '"' || true)"
fi
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Нет GITHUB_TOKEN: положи его в ./install-secrets.env или передай в команде —" >&2
  echo "  GITHUB_TOKEN=<ключ> bash" >&2
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
