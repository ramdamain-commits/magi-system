# MAGI System Handoff

最終更新: 2026-03-25

## 1. 現在地

- 現行アプリは `index.html` の単一ファイル構成
- `RUN MODE` は `DEMO` と `GEMINI` の 2 モード
- `DEMO` はブラウザ内の疑似審議で、API キーなしの無料体験用
- `GEMINI` は API を 1 回だけ呼び、モデルには `panels` を返させて合議は UI 側でローカル合成する
- 入力ミスと通信失敗は `alert()` ではなく、画面上部バナーと inline エラーで案内する
- GitHub Pages 公開先は削除済み（旧 URL: `https://ramdamain-commits.github.io/test-project/`）
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

### 実行モードと API 方針

- `DEMO` は API を使わず、割れ方と UI フローを試すための疑似審議
- `GEMINI` は external call を原則 1 回に制限し、structured output で JSON を返させる
- `RESET` では `AbortController` で Gemini リクエストを中断し、質問文は残す
- 失敗系は `TRUNCATED / FORMAT / EMPTY / SAFETY / QUOTA / RATE LIMIT / AUTH / REQUEST / NETWORK` を大別し、画面内で案内する

## 3. コード上の重要ポイント

- `HOW TO PLAY` と `RUN MODE` の UI は `index.html` の 745 行付近以降
- モード定義、モデル名、schema は `index.html` の 946 行付近以降
- `panels only` の指示は `index.html` の 1235 行付近
- JSON 抽出は `index.html` の 1348 行付近以降
- 合議のローカル合成は `index.html` の 1545 行付近以降
- `DEMO` の疑似審議生成は `index.html` の 1655 行付近以降
- Gemini 呼び出しは `index.html` の 1670 行付近以降
- エラー分類は `index.html` の 1718 行付近以降
- 画面内エラー表示と合議描画は `index.html` の 1879 行付近以降
- 実行フローと `RESET` は `index.html` の 1950 行付近以降

## 4. 既知の論点

### 優先で触るべきもの

1. `panels only` 契約の整理  
   プロンプトでは `consensus を返さない` としているが、受信側ではまだ `payload.consensus` を読む後方互換分岐が残っている。  
   参照箇所: `index.html` の 1235 行付近、1608 行付近

2. 実 API 前提の回帰 QA の固定化  
   `DEMO` は確認済みだが、`GEMINI` は有効な API キーを使った再確認が未了。  
   失敗しやすい観点は `FORMAT ERROR`、`TRUNCATED`、`QUOTA / RATE LIMIT`、人格の収束。

3. ゲーム性の本命機能が未着手  
   `再審議ループ`、差分比較、良い問いテンプレ導線、ローカル実AIモードはまだ未実装。

### いまは問題ではないもの

- 文字コードチェックは repo 内の tracked text files を対象に拡張済み
- `.editorconfig` と checker の source of truth ずれは解消済み
- PR テンプレは日本語化済み

## 5. 次にやる順番

1. 有効な Gemini API キーでスモークテストし、モード分岐後の実 API 回帰を確認する
2. `payload.consensus` の後方互換分岐を残すか削るか決めて、`panels only` 契約に揃える
3. `WebLLM` / `Gemma` 系のローカル実AIモードを検証する

## 6. 実 API QA の最小セット

### 代表質問

- `生成AIで採用一次面接を自動化すべきか`
- `従業員監視AIを導入すべきか`
- `学校で顔認証の出席管理を導入すべきか`
- `新規事業のアイデア出しだけをAIに任せるべきか`

### 確認観点

- 3 パネルが表示されるか
- `FORMAT ERROR` や `TRUNCATED` が出ないか
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
# GitHub repo 削除済み — 公開サイトなし
```

## 8. 直近の履歴（GitHub repo 削除済み — PR リンクはアーカイブ参照）

- 2026-03-24: `DEMO` / `GEMINI` の 2 モード化、初回導線の再配置、画面内バナーと inline エラーを追加
- PR #16: 文字コードチェッカーの対象を tracked text files まで拡張
- PR #15: checker が `.editorconfig` の `charset` を参照するよう修正
- PR #14: setting rollout に合わせて文字コード運用と PR テンプレを導入
- PR #12: `RESPONSE TOO LONG` 対策と実 API テスト
- PR #8: 3 API call から single call MAGI へ構成変更

## 9. 次スレッドの最初に伝えると早いこと

- `docs/HANDOFF.md` を前提に会話を始めること
- もし次が実装スレッドなら、「まず Gemini 実 API 確認か local AI PoC から」と明示するとブレにくい
- 実 API を流す場合は free tier の quota にすぐ当たるので、テスト回数を絞ること
