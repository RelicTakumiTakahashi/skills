# dependency-impact

npm・Composer の更新について、リリースノート、コードの利用箇所、CI の結果から影響を調べる。ロックファイルの比較は package-lock.json（v2・v3）と composer.lock に対応する。

## 手元で PR を調べる

このディレクトリを丸ごと `~/.claude/skills/dependency-impact/` にコピーする。Git、GitHub CLI、Bash、jq を用意し、対象リポジトリで Claude Code を起動する。

- `/dependency-impact 123` は PR #123 を調べる。
- `/dependency-impact uuid 11.0.0` は指定の版まで上げた場合の影響を調べる。
- `/dependency-impact` は現在のブランチの依存更新を調べる。

## GitHub Actions で定期実行する

1. 利用先のリポジトリに Claude GitHub App をインストールし、Actions secret に `CLAUDE_CODE_OAUTH_TOKEN` を登録する。
2. [呼び出し例](../examples/dependabot-review.yml) を利用先の `.github/workflows/dependabot-review.yml` にコピーする。特定の版に固定する場合は `@main` を公開済みのコミット SHA に置き換える。スキル本文と解析スクリプトも同じコミットから読み込まれる。
3. 既定ブランチに追加すると、平日 12:00（日本時間）に最大5件を調査する。Actions タブから PR 番号を指定すると、同じコミットでも再調査できる。

GitHub.com 向け。対象は同じリポジトリ内の開いた Dependabot PR で、変更ファイルが npm・Composer のマニフェストと対応するロックファイルに収まるもの。CI の実行中は次回に回す。既定では調査結果を日本語でコメントする。

| 呼び出し側の `with` | 有効にしたときの動作 |
|---|---|
| `auto_fix: true` | 更新が原因で修正方法が明確なとき、Claude GitHub App が PR ブランチに修正を push する。App には Contents の書き込み権限が必要。修正済み PR には `claude-fixed` ラベルを付け、人がレビューする。 |
| `auto_approve: true` | 問題が見つからず、調査したコミットが現在も先端で、依存一覧の省略や修正がなく、Dependabot の署名付きコミットだけを含む場合に承認する。利用先の Actions 設定で GitHub Actions による PR の承認を許可する。 |

どちらも既定値は false。マージは利用側で判断する。
