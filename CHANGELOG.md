# Changelog

## 2026-03-08

### Changed

- `index.html` の審議フローを、3 並列 API 呼び出しから 1 回の Gemini 呼び出し + ローカル段階表示へ切り替えた
- 3 本のストリームを直接描画する方式をやめ、`BALTHASAR -> CASPAR -> MELCHIOR -> CONSENSUS` の順に UI 側で開示する方式へ変更した
- Gemini への要求を自由文から短い JSON 構造へ寄せ、`panels` と `consensus` をまとめて返す構成へ変えた
- 各人格の `reasons` を最大 2 件、`conditions` を最大 2 件に抑え、トークン消費を削減した
- `RESET` で進行中のリクエストを中断し、無駄な API 消費を止めるようにした
- 問い入力欄と API 設定欄の文言を、単発審議モードに合わせて更新した
- 合議表示の補助文言を `SINGLE REQUEST / LOCAL REVEAL` ベースに更新した

### Fixed

- `index.html` の判定パーサーを厳密化し、`承認条件` を含むだけの応答を誤って `承認` 扱いしないようにした
- 単独の `承認 / 否決` 行が `理由` に混ざるケースを吸収し、判定抽出を安定させた
- JSON 欠損や不正レスポンス時に `FORMAT ERROR` を返し、審議失敗の理由を見分けやすくした
- API エラーを `RATE LIMITED / AUTH ERROR / SAFETY BLOCK / NO RESPONSE / REQUEST ERROR` に分類するようにした

### Added

- `README.md` に単発審議アーキテクチャと API 負荷軽減方針を追記した
- `docs/UPDATE_POLICY.md` に API 負荷軽減の原則、JSON 契約、ゲーム性維持ルールを明文化した
- `CLAUDE.md` に 1 リクエスト構成と更新ルールを反映した
- 全員一致でも潜在的な反対論点を残すための `minority_view` フォールバックを追加した
- 構造化レスポンス検証用のローカルハーネスで、正常系と `FORMAT ERROR` の両方を確認した

### Notes

- 3 パネル UI と合議カードの見せ方は維持しつつ、外部 API 呼び出し数だけを削減している
- 今回はブラウザ実機での Gemini 応答までは未確認で、ローカルの Node ハーネスで構文と整形ロジックを確認している
