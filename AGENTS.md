# MAGI System - Project Guide

## 概要
エヴァンゲリオン風の意思決定UIアプリ。3つのAIパネル（BALTHASAR/CASPAR/MELCHIOR）の審議を1回のGeminiリクエストから生成し、合議はローカルで合成して対立・少数意見・承認条件を可視化する。

## 開発目的
- 重要な判断を AI に委任するのではなく、異なる価値観を衝突させて blind spot を減らす
- UI と API 連携の見栄え中心の段階から、ゲーム性と審議品質を鍛える段階へ移行する
- 良いアプリの条件を「満場一致」ではなく「なぜ割れたかが読めること」に置く

## ファイル構成
- `index.html` — メインアプリ（現行バージョン）
- `docs/UPDATE_POLICY.md` — 開発目的と更新方針
- `CHANGELOG.md` — 変更履歴
- `.github/pull_request_template.md` — 日本語 PR テンプレート

## 技術スタック
- 純粋な HTML / CSS / Vanilla JS（ビルド不要）
- Gemini API（`generativelanguage.googleapis.com`）を1回呼び、構造化レスポンスを受け取る
- APIキーはブラウザのみで処理、サーバー送信なし

## 開発サーバー
```
# Node.js で静的配信（ポート3000）
# .Codex/launch.json 経由で preview_start "static-server" を使う
```

## コーディング規約
- フレームワーク・ビルドツールは使わない（シンプルに保つ）
- スタイルは `<style>` タグ内にまとめる
- JS は `<script>` タグ内にまとめる
- CSS 変数（`--amber` 等）でテーマカラーを管理
- モバイル対応必須（`max-width: 500px` のメディアクエリあり）
- 仕様変更時は `README.md`、`CHANGELOG.md`、関連ドキュメントの更新要否を確認する
- ドキュメントと GitHub PR は原則として日本語で書く
- テキストの文字コードは `.editorconfig` を正とし、Markdown と PowerShell は UTF-8 BOM、その他のテキストは UTF-8 を基本にする
- GitHub PR は `.github/pull_request_template.md` を使い、必要なら `C:\Users\ramda\projects\setting\Run-GitHubPrCreate.cmd` を使う

## Git / GitHub
- メインブランチ: `main`
- 機能追加は `codex/` プレフィックス付きブランチで作業
- PR は `gh pr create` で作成済みワークフロー
