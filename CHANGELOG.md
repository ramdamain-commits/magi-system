# Changelog

## 2026-03-09

### Added

- `.editorconfig` を追加し、Markdown と PowerShell を UTF-8 BOM、その他テキストを UTF-8 で扱う編集規約を明示した
- `.github/pull_request_template.md` を追加し、日本語 PR の目的、影響範囲、確認内容を揃えやすくした
- `.github/workflows/text-encoding-check.yml` と `scripts/Test-TextEncoding.ps1` を追加し、PR ごとに再帰的な文字コードチェックを自動実行するようにした

### Changed

- `README.md` と `docs/UPDATE_POLICY.md`、`AGENTS.md`、`CLAUDE.md` に文書言語と文字コード運用を追記した
- `scripts/Test-TextEncoding.ps1` が `.editorconfig` の `charset` 定義を参照して判定するようにし、文字コード運用の source of truth と実装を揃えた

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
