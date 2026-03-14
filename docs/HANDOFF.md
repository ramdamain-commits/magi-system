# MAGI System Handoff

最終更新: 2026-03-15

## 1. 現在地

- 現行アプリは `index.html` の単一ファイル構成
- 3 パネル UI は維持しつつ、Gemini API は 1 回だけ呼ぶ
- モデルには `panels` だけを返させ、合議は UI 側でローカル合成する
- GitHub Pages 公開先は <https://ramdamain-commits.github.io/test-project/>
- 文字コード運用は `.editorconfig` が source of truth。PR では `.github/workflows/text-encoding-check.yml` が `scripts/Test-TextEncoding.ps1 -Recurse -FailOnWarning` を実行する

## 2. いまの仕様の要点

### プロダクト目的

- AI に最終判断させるのではなく、異なる価値観を衝突させて blind spot を減らす
- 満場一致より「どこで割れたか」を読ませる
- UI の見栄えだけでなく、ゲーム性と審議品質を優先する

### 審議構成

- `BALTHASAR-2`: 前提破壊。常識、楽観、権威依存を疑う
- `CASPAR-3`: 被害監査。権利侵害、悪用、炎上、弱者への負荷を見る
- `MELCHIOR-1`: 執行責任。実装、運用、責任者、撤退条件を見る
- 各パネルは `結論 / 理由 / 最大リスク / 承認条件 / 判定` を表示
- 合議エリアは `最終判定 / 投票結果 / 多数派 / 少数意見 / 保留条件 / 推奨アクション` を表示

### API 方針

- 外部 API 呼び出しは原則 1 回
- structured output を使って JSON を返させる
- `RESET` では `AbortController` でリクエストを中断する
- 失敗系は `RESPONSE TOO LONG / FORMAT ERROR / RATE LIMITED / SAFETY / REQUEST ERROR` に分けて表示する

## 3. コード上の重要ポイント

- プロンプトと schema は `index.html` の 673 行付近以降
- `panels only` の指示は `index.html` の 734 行付近以降
- Gemini 呼び出しは `index.html` の 1118 行付近以降
- エラー分類は `index.html` の 1170 行付近以降
- 合議表示は `index.html` の 1286 行付近以降
- 実行フローは `index.html` の 1342 行付近以降

## 4. 既知の論点

### 優先で触るべきもの

1. `panels only` 契約の整理  
   プロンプトでは `consensus を返さない` としているが、受信側ではまだ `payload.consensus` を読む分岐が残っている。  
   参照箇所: `index.html` の 738 行付近、1093 行付近

2. 実 API 前提の回帰 QA の固定化  
   今は個別確認はしているが、質問セットと期待観点がまだ文書化し切れていない。  
   失敗しやすい観点は `FORMAT ERROR`、`RESPONSE TOO LONG`、`RATE LIMITED`、人格の収束。

3. ゲーム性の本命機能が未着手  
   `再審議ループ`、差分比較、良い問いテンプレ導線はまだ未実装。

### いまは問題ではないもの

- 文字コードチェックは repo 内の tracked text files を対象に拡張済み
- `.editorconfig` と checker の source of truth ずれは解消済み
- PR テンプレは日本語化済み

## 5. 次にやる順番

1. `payload.consensus` の後方互換分岐を残すか削るか決めて、`panels only` 契約に揃える
2. 実 API の回帰 QA を `docs/HANDOFF.md` か別ドキュメントに固定化する
3. `再審議ループ` の UI と state 設計に入る

## 6. 実 API QA の最小セット

### 代表質問

- `生成AIで採用一次面接を自動化すべきか`
- `従業員監視AIを導入すべきか`
- `学校で顔認証の出席管理を導入すべきか`
- `新規事業のアイデア出しだけをAIに任せるべきか`

### 確認観点

- 3 パネルが表示されるか
- `FORMAT ERROR` や `RESPONSE TOO LONG` が出ないか
- 少数意見が残るか
- `2 approve / 1 reject` と最終判定の整合が取れているか
- `RESET` でリクエスト中断が効くか

## 7. よく使うコマンド

```powershell
# 文字コードチェック
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-TextEncoding.ps1 -Recurse -FailOnWarning

# 状態確認
git status --short --branch

# 公開サイト
start https://ramdamain-commits.github.io/test-project/
```

## 8. 直近の履歴

- PR [#16](https://github.com/ramdamain-commits/test-project/pull/16): 文字コードチェッカーの対象を tracked text files まで拡張
- PR [#15](https://github.com/ramdamain-commits/test-project/pull/15): checker が `.editorconfig` の `charset` を参照するよう修正
- PR [#14](https://github.com/ramdamain-commits/test-project/pull/14): setting rollout に合わせて文字コード運用と PR テンプレを導入
- PR [#12](https://github.com/ramdamain-commits/test-project/pull/12): `RESPONSE TOO LONG` 対策と実 API テスト
- PR [#8](https://github.com/ramdamain-commits/test-project/pull/8): 3 API call から single call MAGI へ構成変更

## 9. 次スレッドの最初に伝えると早いこと

- `docs/HANDOFF.md` を前提に会話を始めること
- もし次が実装スレッドなら、「まず panels-only 契約整理から」と明示するとブレにくい
- 実 API を流す場合は free tier の quota にすぐ当たるので、テスト回数を絞ること
