#!/usr/bin/env bash
# ロックファイルの 2 つの版を比べ、新しく入ったパッケージ（+）、消えたパッケージ（-）、版が変わったパッケージ（~）を出す
# 使い方: lock-changes.sh <旧の ref> <新の ref> <ロックファイル>...
set -euo pipefail

# Claude Code のサンドボックスではホームの設定を読めず git が止まるため、グローバル設定は読まない
export GIT_CONFIG_GLOBAL=/dev/null
export LC_ALL=C

old_ref=$1
new_ref=$2
shift 2

# $(...) の中では set -e が効かないため、失敗は return で明示的に返す
list() {
  local entry content
  # 片方の版に無いロックファイルは空として比べる。読めないだけの場合に全件を「消えた」と誤って出さないよう、有無は木で確かめる
  entry=$(git ls-tree "$1" -- "$2") || return 1
  [ -n "$entry" ] || return 0
  content=$(git show "$1:$2") || return 1
  case "$2" in
    *composer.lock)
      jq -r '(.packages // []) + (.["packages-dev"] // []) | .[] | "\(.name)\t\(.version)"' <<< "$content"
      ;;
    *package-lock.json)
      jq -r '(.packages // error("package-lock v2/v3 required")) | to_entries[] | select(.key != "") | "\(.key | sub("^.*node_modules/"; ""))\t\(.value.version // "")"' <<< "$content"
      ;;
  esac | sort -u
}

for lock in "$@"; do
  # プロセス置換の中で list を呼ぶと失敗が握りつぶされるため、先に変数へ受ける
  old=$(list "$old_ref" "$lock")
  new=$(list "$new_ref" "$lock")
  echo "## $lock"
  # npm は同じパッケージが複数の版で入りうるため、版はパッケージ名ごとにまとめて比べる
  awk -F '\t' '
    $1 == "" { next }
    FNR == NR { old[$1] = ($1 in old) ? old[$1] ", " $2 : $2; next }
    { new[$1] = ($1 in new) ? new[$1] ", " $2 : $2 }
    END {
      for (k in new) if (!(k in old)) print "+ " k " " new[k]
      for (k in old) if (!(k in new)) print "- " k " " old[k]
      for (k in old) if ((k in new) && old[k] != new[k]) print "~ " k " " old[k] " -> " new[k]
    }
  ' <(echo "$old") <(echo "$new") | sort
done
