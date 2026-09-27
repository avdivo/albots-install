#!/usr/bin/env bash
# ALBots one-line installer (public loader).
# Скачивает приватный установщик из avdivo/bot_platform и запускает его.
#
# Использование (ключ нужен один раз, read-only PAT на чтение приватного репо):
#   cd <папка>                 # сюда кладём файл настроек (install-secrets.env
#                              #   или единственный *.env)
#   curl -fsSL https://raw.githubusercontent.com/avdivo/albots-install/main/install.sh | bash
#
# Папка запуска = «корень развёртывания»: в ней лежит файл настроек, а
# установка идёт в её подкаталог albots/ (albots1, …). Одинаково на сервере и на
# локальной машине. GITHUB_TOKEN берётся из окружения или из файла настроек.
# Аргументы пробрасываются в deploy/install.sh:
#   --clean — переставить заново.
set -euo pipefail

REPO="${ALBOTS_REPO:-avdivo/bot_platform}"
BRANCH="${ALBOTS_BRANCH:-main}"

# Ключ для скачивания: окружение → файл настроек (install-secrets.env или
# единственный *.env в папке запуска) → старые места.
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  _envs=()
  if [[ -f "$PWD/install-secrets.env" ]]; then
    _envs+=("$PWD/install-secrets.env")
  else
    for _f in "$PWD"/*.env; do
      [[ -f "$_f" ]] && _envs+=("$_f")
    done
  fi
  if ((${#_envs[@]} == 1)); then
    GITHUB_TOKEN="$(grep -oP '^GITHUB_TOKEN=\K.*' "${_envs[0]}" 2>/dev/null | tr -d '"' || true)"
  fi
  unset _envs _f
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
