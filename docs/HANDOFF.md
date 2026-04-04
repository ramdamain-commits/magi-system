# MAGI System Handoff

最終更新: 2026-03-29

## 1. 現在地

- 現行アプリは `index.html` の単一ファイル構成
- `RUN MODE` は `DEMO`、`GEMINI`、`LOCAL AI`（実験的）の 3 モード
- `DEMO` はブラウザ内の疑似審議で、API キーなしの無料体験用
- `GEMINI` は API を 1 回だけ呼び、モデルには `panels` を返させて合議は UI 側でローカル合成する
- `LOCAL AI` は WebLLM + Qwen2.5-3B で panel 個別生成を行う実験的モード。品質基準未達時は `DEMO` へ自動フォールバックする
- 入力ミスと通信失敗は `alert()` ではなく、画面上部バナーと inline エラーで案内する
- 再審議ボタンと差分比較機能で、同じ問いを繰り返し審議してゲーム性を高められる
- 良い問いテンプレ 8 件をクリック可能なチップとして UI に統合した
- 文字コード運用は `.editorconfig` が source of truth。PR では `.github/workflows/text-encoding-check.yml` が `scripts/Test-TextEncoding.ps1 -Recurse -FailOnWarning` を実行する

### 現行公開状態

| リソース | URL | 状態 |
|----------|-----|------|
| GitHub Pages（現行） | `https://ramdamain-commits.github.io/magi-system/` | 公開中 |
| GitHub repo | `https://github.com/ramdamain-commits/magi-system` | public |

### 旧公開履歴

| リソース | URL | 状態 |
|----------|-----|------|
| GitHub Pages（旧 repo `test-project`） | `https://ramdamain-commits.github.io/test-project/` | repo 削除に伴い消滅（404） |
| GitHub repo（旧） | `https://github.com/ramdamain-commits/test-project` | 削除済み（404） |

旧 repo `test-project` からの移行は完了しており、現行コードと公開サイトはすべて `magi-system` repo に集約されている。

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
- `LOCAL AI` は WebLLM でブラウザ内推論を行う実験的モード。panel 個別生成 + 品質スコアリング + 自動フォールバック
- `RESET` では `AbortController` で Gemini リクエストを中断し、質問文は残す
- 失敗系は `TRUNCATED / FORMAT / EMPTY / SAFETY / QUOTA / RATE LIMIT / AUTH / REQUEST / NETWORK / WEBGPU / LOCAL_INIT / LOW_QUALITY` を大別し、画面内で案内する

## 3. コード上の重要ポイント

- `HOW TO PLAY` と `RUN MODE` の UI は `index.html` の `quickstart` と `setup-wrap`
- モード定義、schema、人格定義は `RUN_MODE_META`、`MAGI_RESPONSE_SCHEMA`、`MAGI`
- `panels only` の指示は `buildSingleMagiPrompt()`
- JSON 抽出は `extractJsonPayload()` と `buildValidatedDeliberation()`（consensus 互換分岐は削除済み）
- 合議のローカル合成は `buildConsensusFromPanels(panels, voteSummaryOverride)`（overrides 廃止、panels のみ正規入力）
- `DEMO` の疑似審議生成は `buildDemoDeliberation()`（`deliberationCount` を seed に含め、再審議で結果が変化する）
- Gemini 呼び出しは `callGeminiOnce()`
- LOCAL AI のエンジン管理は `ensureLocalEngine()`、panel 生成は `callLocalPanel()`、統合は `executeLocalAi()`
- 品質スコアリングは `scoreLocalPanelQuality()`（日本語含有を含む 5 点満点、閾値 3）
- 再審議と差分比較は `reDeliberate()`、`updateDiffSection()`、`buildDiffHtml()`
- エラー分類は `classifyError()`（LOCAL AI 系エラーコード追加済み）
- 実行フローと `RESET` は `execute()` と `resetAll()`

## 4. KPT

### Keep

- `DEMO` は API キー不要で UX の入口として有効だった。無料体験ルートとして今後も維持しやすい
- `GEMINI` を 1 回だけ呼んで、`panels` から UI 側で合議を作る構成は、コストと演出の両立に向いている
- `LOCAL AI` でも 3 人格一括生成より panel 個別生成の方が完走率は上がった。この知見は別 PoC でも再利用できる

### Problem

- `LOCAL AI` の実機 QA は安定しなかった。Windows + Chrome 146 + WebLLM で、3人格一括生成は `5/5` 件が `finishReason:length` で失敗した
- panel 個別生成へ寄せると完走率は一時 `4/5` まで上がったが、空欄寄り、英単語混入、`approve / none / high` のような粗い値が混ざり、品質が足りなかった
- schema を締めた再計測では `2/5` 成功、`max_tokens=240` の抜き打ち再計測でも `1/2` 成功に留まった
- 小型ローカルモデルは WebGPU、VRAM、ブラウザ差分の影響が大きく、無料化の入口としては説明コストと失敗率が高すぎた

### Try

- ローカル推論を再挑戦するなら、ユーザー向けモードには戻さず PoC ブランチか別スレッドで進める
- 1B 前提の微調整より、JSON 完走率が高い 2B〜3B 級モデルや別 family を先に検証する
- 再導入条件は、代表質問 5 件程度で安定成功し、内容も日本語で最低限読めること。未達なら `DEMO` を無料ルートに維持する
- fallback は最初から設計し、`TRUNCATED` や低品質時に `DEMO` か `GEMINI` へ誘導する

## 5. 既知の論点

1. ~~`panels only` 契約の整理~~ → **完了**（2026-03-26）。consensus 互換分岐を削除し、panels のみ正規入力とした
2. ~~ゲーム性の本命機能が未着手~~ → **完了**（2026-03-26）。再審議ループ、差分比較、良い問いテンプレ導線を実装した
3. ~~`LOCAL AI` 再挑戦~~ → **実験的モードとして再導入**（2026-03-26）。WebLLM + Qwen2.5-3B で panel 個別生成 + 品質スコアリング + DEMO フォールバック。安定基準（代表質問 5 件で安定成功）は未検証
4. ~~`LOCAL AI` の実機 QA~~ → **フォールバック動作確認済み**（2026-03-29）。WebGPU 非対応環境で CDN 接続失敗 → DEMO フォールバックが正常動作。WebGPU 対応環境での推論品質は未検証
5. ~~テンプレートの問い 8 件の妥当性検証~~ → **改善済み**（2026-03-29）。キーワードルール調整とテンプレート拡充により、8 問中 6 問が 2A/1R、2 問が 1A/2R と多様な割れ方になった。再審議時の結果変化も確認済み
6. ~~Gemini API 無料枠テスト~~ → **確認済み**（2026-03-29）。代表質問 1 問で 3 パネル表示、少数意見残存、投票と判定の整合を確認した

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
- `DEMO` は無料体験として違和感なく流れが分かるか
- `GEMINI` は API キー未入力時の画面内エラーが分かりやすいか

## 7. よく使うコマンド

```powershell
# 文字コードチェック
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-TextEncoding.ps1 -Recurse -FailOnWarning

# 状態確認
git status --short --branch

# 公開サイト（現行）
# https://ramdamain-commits.github.io/magi-system/
# （旧 repo test-project は削除済み。詳細はセクション 1「現行公開状態」「旧公開履歴」を参照）
```

## 8. 直近の履歴

> 旧 repo `test-project` の PR リンク（#8, #12, #14, #15, #16）は旧 repo 削除に伴いアクセス不可。内容はセクション 1「旧公開履歴」を参照。

- 2026-03-29: DEMO キーワードルール調整・テンプレート拡充（3→5件）・再審議バリエーション追加。LOCAL AI フォールバック動作確認。Gemini API 実機テスト成功
- 2026-03-26: `panels only` 契約整理（consensus 互換分岐削除）、ゲーム性強化（再審議・差分比較・テンプレチップ）、LOCAL AI 実験モード再導入を実装した
- 2026-03-25: WebLLM を使う `LOCAL AI` の PoC を試し、実機 QA で `finishReason:length` と低品質応答の傾向を確認した
- 2026-03-25: `LOCAL AI` をユーザー向けモードから外し、知見をこの文書の `KPT` に集約した
- 2026-03-24: `DEMO` / `GEMINI` の 2 モード化、初回導線の再配置、画面内バナーと inline エラーを追加
- PR #16: 文字コードチェッカーの対象を tracked text files まで拡張
- PR #15: checker が `.editorconfig` の `charset` を参照するよう修正
- PR #14: setting rollout に合わせて文字コード運用と PR テンプレを導入
- PR #12: `RESPONSE TOO LONG` 対策と実 API テスト
- PR #8: 3 API call から single call MAGI へ構成変更

## 9. 次スレッドの最初に伝えると早いこと

- `docs/HANDOFF.md` を前提に会話を始めること
- DEMO のキーワードルール・テンプレート改善、LOCAL AI フォールバック確認、Gemini API テストは完了済み
- `LOCAL AI` は WebGPU 非対応環境でのフォールバック動作は確認済みだが、WebGPU 対応環境での推論品質は未検証
- 実 API を流す場合は free tier の quota にすぐ当たるので、テスト回数を絞ること
- 現行の公開先は `https://ramdamain-commits.github.io/magi-system/`（公開中）。旧 repo `test-project` の経緯はセクション 1「旧公開履歴」を参照
