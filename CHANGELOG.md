# Changelog

## 2026-03-29

### Changed

- `DEMO_LIBRARY` を各パネルの approve/reject 各 5 件から 10 件に拡充し、審議バリエーションを増やした
  - BALTHASAR approve 追加: 異端の視点・少数派視点・反証込み・代替案・逆張り承認
  - BALTHASAR reject 追加: 業界標準依存・大手依存・実績頼み・ベストプラクティス盲信・前例踏襲
  - CASPAR approve 追加: 匿名化前提・影響範囲限定・第三者監査・情報開示・教育目的
  - CASPAR reject 追加: 高齢者リスク・プロファイリング・追跡設計・生体情報不可逆・スコアリング
  - MELCHIOR approve 追加: マニュアル整備・引き継ぎ設計・ROI可視化・自動テスト・監視体制
  - MELCHIOR reject 追加: 属人化リスク・スケール不可能・兼務破綻・暫定恒常化・手動限界
- `DEMO_SIGNAL_RULES` にドメイン固有キーワードを追加した
  - BALTHASAR positive に `'プロトタイプ'`, `'逆張り'`, `'少数派'`, `'反証'`, `'代替案'` を追加
  - BALTHASAR negative に `'業界標準'`, `'ベストプラクティス'`, `'前例'`, `'大手'`, `'実績'` を追加
  - CASPAR positive に `'透明性'`, `'第三者'`, `'被害者'`, `'教育'`, `'情報開示'` を追加
  - CASPAR negative に `'プロファイリング'`, `'スコアリング'`, `'追跡'`, `'生体'`, `'高齢者'` を追加
  - MELCHIOR positive に `'マニュアル'`, `'引き継ぎ'`, `'roi'`, `'自動テスト'`, `'監視'` を追加
  - MELCHIOR negative に `'属人'`, `'手動'`, `'兼務'`, `'残業'`, `'暫定'` を追加
- コンセンサスヘッダーに「第N回審議」を表示するようにした（`cs-label` 要素を `showConsensus` 内で更新）
- `DEMO_SIGNAL_RULES` を調整し、テンプレ 8 問で 2A/1R と 1A/2R の両パターンが出るようにした
  - BALTHASAR の `negative` から汎用的すぎる `'ai'` を除外し、`positive` に `'アイデア'`, `'一次'`, `'スクリーニング'` を追加
  - CASPAR の `positive` に `'対策'`, `'スクリーニング'` を追加、`negative` から `'医療'`, `'炎上'` を除外
  - MELCHIOR の `positive` に `'導入'`, `'管理'`, `'出席'` を追加、`negative` から `'自動化'` を除外
- `DEMO_LIBRARY` の各パネル approve/reject テンプレートを 3 → 5 件に拡充し、応答バリエーションを増やした
- `scoreDemoPanel`, `createDemoPanel`, `rebalanceDemoPanels`, `buildDemoDeliberation` に `round`（審議回数）を渡すようにし、再審議時にスコアとテンプレート選択が変化するようにした
- `scoreDemoPanel` の drift 係数を 0.9 → 1.2 に引き上げ、キーワードヒット差が小さい質問で結果が揺れやすくした

### Fixed

- `docs/HANDOFF.md` の「削除済み/公開サイトなし」を正確な記述に修正（旧 repo 削除済み + 現行公開 URL を明記）

### Verified

- LOCAL AI: WebGPU 非対応環境で CDN 接続失敗 → DEMO フォールバックが正常に動作することを確認した
- DEMO: テンプレ 8 問中 6 問が 2A/1R、2 問が 1A/2R と割れ、改善前の全問 1A/2R から多様性が向上した
- DEMO: 再審議で同じ質問でも verdict が変化する（例: round 0→1A/2R, round 2→2A/1R）ことを確認した
- GEMINI: API キーを使った実審議で 3 パネル表示、少数意見残存、投票と判定の整合を確認した

## 2026-03-26

### Changed

- `buildConsensusFromPanels` から `overrides` パラメータを削除し、`panels` のみを正規入力とする契約に整理した
- `buildValidatedDeliberation` から `payload.consensus` の後方互換分岐を削除した
- `getPanelSource` から `payload` 直読みのフォールバック（`panels` キーがない場合の互換）を削除した
- プロンプト指示（`consensus を返さない`）と受信側コードの整合を取った

### Added

- 再審議ボタン: 同じ問いで何度でも審議を実行でき、審議回数を表示する
- 差分比較: 前回と今回の審議結果（判定、結論、リスク、理由、最終判定）の変化を表示する
- 良い問いテンプレ導線: 衝突しやすい入力例 8 件をクリック可能なチップとして UI に統合した
- `LOCAL AI` 実験モード: WebLLM + Qwen2.5-3B で panel 個別生成を行う実験的モードを追加した
- `LOCAL AI` の品質基準未達時に `DEMO` モードへ自動フォールバックする導線を組み込んだ
- `LOCAL AI` のモデルダウンロード進捗バーと WebGPU 非対応時のエラー案内を追加した

### Notes

- `LOCAL AI` は「実験的」ラベル付きで提供し、安定基準（代表質問 5 件で安定成功 + 日本語で最低限読める）を満たすまでは fallback 前提の運用とする
- 再審議・差分比較は `UPDATE_POLICY.md` の 7 番「ゲーム性を高める方針」に基づく実装
- `panels only` 契約整理により、API が `consensus` を返しても UI は無視し `panels` だけで表示を成立させる設計になった

## 2026-03-25

### Removed

- `index.html` から `LOCAL AI` 実行モードを外し、`DEMO / GEMINI` の 2 モード構成へ戻した

### Added

- WebLLM を使う `LOCAL AI` の PoC を試し、実機 QA で詰まる観点を洗い出した

### Changed

- `README.md`、`docs/UPDATE_POLICY.md`、`docs/HANDOFF.md`、`CLAUDE.md` を 2 モード前提へ戻し、`LOCAL AI` の知見は handoff の `KPT` に集約した
- `GEMINI` 専用の API キー導線とエラー導線は維持しつつ、無料体験は `DEMO` に一本化した

### Notes

- `LOCAL AI` は `finishReason:length` と応答品質のばらつきが大きく、ユーザー向け実行モードとしては維持しない判断にした

## 2026-03-24

### Added

- `index.html` に `DEMO` / `GEMINI` の実行モードを追加し、API キーなしでも無料で遊べる疑似審議ルートを用意した
- 初回導線として `HOW TO PLAY`、`RUN MODE`、画面内エラーバナー、入力欄下の inline エラーを追加した

### Changed

- `index.html` のレイアウトを入力導線優先に組み替え、`API KEY` 設定を問い入力より上に移した
- `index.html` の文字サイズ、色コントラスト、モバイル時の 1 カラム表示を見直し、可読性を上げた
- `RESET` が問いを消さず、審議だけ中断して再実行しやすい挙動に変わった
- `README.md` に実行モード、UI / エラー方針、更新後の使い方を反映した
- `docs/UPDATE_POLICY.md` に `DEMO` モードの位置づけとエラー案内の原則を追記した
- `CLAUDE.md` に `DEMO` は疑似審議と明示し、エラーは画面内で案内する運用ルールを追記した

### Fixed

- `alert()` 依存だった入力エラーを画面内の案内へ置き換え、初回利用時に文脈が切れないようにした
- 通信失敗時に全パネルへ同じエラー本文を複写する挙動をやめ、上部バナーで障害内容と次の行動を示すようにした
- `429` 系エラーを `瞬間レート超過` と `無料枠 / 日次上限` で分けて案内し、待てば戻るかどうかを見分けやすくした

## 2026-03-15

### Added

- `docs/HANDOFF.md` を追加し、別スレッドへ渡すための現状、既知の論点、次の優先順位、QA 観点を 1 枚にまとめた

### Changed

- `README.md` の開発ファイル一覧に引き継ぎ文書を追加した

## 2026-03-09

### Added

- `.editorconfig` を追加し、Markdown と PowerShell を UTF-8 BOM、その他テキストを UTF-8 で扱う編集規約を明示した
- `.github/pull_request_template.md` を追加し、日本語 PR の目的、影響範囲、確認内容を揃えやすくした
- `.github/workflows/text-encoding-check.yml` と `scripts/Test-TextEncoding.ps1` を追加し、PR ごとに再帰的な文字コードチェックを自動実行するようにした

### Changed

- `README.md` と `docs/UPDATE_POLICY.md`、`AGENTS.md`、`CLAUDE.md` に文書言語と文字コード運用を追記した
- `scripts/Test-TextEncoding.ps1` が `.editorconfig` の `charset` 定義を参照して判定するようにし、文字コード運用の source of truth と実装を揃えた
- `scripts/Test-TextEncoding.ps1` が `-Recurse` 時に Git 管理下のテキストファイル全体を対象にするようにし、`index.html` や `.gitignore` などの取りこぼしを防ぐようにした

## 2026-03-08

### Changed

- `index.html` の審議フローを、3 並列 API 呼び出しから 1 回の Gemini 呼び出し + ローカル段階表示へ切り替えた
- 3 本のストリームを直接描画する方式をやめ、`BALTHASAR -> CASPAR -> MELCHIOR -> CONSENSUS` の順に UI 側で開示する方式へ変更した
- Gemini への要求を自由文から短い JSON 構造へ寄せ、モデルは `panels` を返し、`consensus` は UI 側で合成する構成へ変えた
- 各人格の `reasons` を最大 1 件、`conditions` を最大 1 件に抑え、トークン消費をさらに削減した
- `RESET` で進行中のリクエストを中断し、無駄な API 消費を止めるようにした
- 問い入力欄と API 設定欄の文言を、単発審議モードに合わせて更新した
- 合議表示の補助文言を `SINGLE REQUEST / LOCAL REVEAL` ベースに更新した

### Fixed

- `index.html` の判定パーサーを厳密化し、`承認条件` を含むだけの応答を誤って `承認` 扱いしないようにした
- 単独の `承認 / 否決` 行が `理由` に混ざるケースを吸収し、判定抽出を安定させた
- JSON 欠損や不正レスポンス時に `FORMAT ERROR` を返し、審議失敗の理由を見分けやすくした
- API エラーを `RATE LIMITED / AUTH ERROR / SAFETY BLOCK / NO RESPONSE / REQUEST ERROR` に分類するようにした
- Gemini 呼び出しに `application/json` と JSON schema を指定し、構造化レスポンスの崩れで `FORMAT ERROR` になりにくくした
- `panels` と `consensus` のキー揺れ、コードブロック、末尾カンマ混入に耐える軽い JSON 復旧処理を追加した
- `HTTP 400` を一律 `AUTH ERROR` にせず、schema 不整合や bad request は `REQUEST ERROR` として案内するようにした
- structured output 向けプロンプトを圧縮し、`maxOutputTokens` を拡張して、JSON が途中で切れやすい状態を緩和した
- `MAX_TOKENS` 由来の打ち切りを `RESPONSE TOO LONG` として分離し、`FORMAT ERROR` と見分けられるようにした
- JSON の `{` だけ返って閉じずに終わるケースを `JSON payload truncated` として検出し、一般的な解析失敗と区別して案内するようにした
- `MAX_TOKENS` でも JSON が完結していれば使えるように、打ち切り判定をパース成功後へ後ろ倒しした

### Added

- `README.md` に単発審議アーキテクチャと API 負荷軽減方針を追記した
- `docs/UPDATE_POLICY.md` に API 負荷軽減の原則、JSON 契約、ゲーム性維持ルールを明文化した
- `CLAUDE.md` に 1 リクエスト構成と更新ルールを反映した
- 全員一致でも潜在的な反対論点を残すための `minority_view` フォールバックを追加した
- 構造化レスポンス検証用のローカルハーネスで、正常系と `FORMAT ERROR` の両方を確認した

### Notes

- 3 パネル UI と合議カードの見せ方は維持しつつ、外部 API 呼び出し数だけを削減している
- 今回はブラウザ実機での Gemini 応答までは未確認で、ローカルの Node ハーネスで構文と整形ロジックを確認している
