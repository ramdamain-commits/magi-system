# MAGI System - Project Guide

## 概要
エヴァンゲリオン風の意思決定 UI アプリ。3つの AI パネル（BALTHASAR / CASPAR / MELCHIOR）の審議を 1 回の Gemini リクエストから生成し、合議はローカルで合成して段階表示する。

## 開発目的
- 重要な判断を AI に委任するのではなく、異なる価値観を衝突させて blind spot を減らす
- UI と API 連携の見栄え中心の段階から、ゲーム性と審議品質を鍛える段階へ移行する
- 良いアプリの条件を「満場一致」ではなく「なぜ割れたかが読めること」に置く
- API 上限で止まりにくい審議ループを作る

## ファイル構成
- `index.html` — メインアプリ（現行バージョン）
- `docs/UPDATE_POLICY.md` — 開発目的と更新方針
- `CHANGELOG.md` — 変更履歴

## 技術スタック
- 純粋な HTML / CSS / Vanilla JS（ビルド不要）
- Gemini API（`generativelanguage.googleapis.com`）を 1 回呼び、構造化レスポンスを受け取る
- 3 パネルの段階表示はクライアント側で制御する
- APIキーはブラウザのみで処理、サーバー送信なし

## 開発サーバー
```
# Node.js で静的配信（ポート3000）
# .claude/launch.json 経由で preview_start "static-server" を使う
```

## コーディング規約
- フレームワーク・ビルドツールは使わない（シンプルに保つ）
- スタイルは `<style>` タグ内にまとめる
- JS は `<script>` タグ内にまとめる
- CSS 変数（`--amber` 等）でテーマカラーを管理
- モバイル対応必須（`max-width: 500px` のメディアクエリあり）
- 仕様変更時は `README.md`、`CHANGELOG.md`、関連ドキュメントの更新要否を確認する
- 通信方式や JSON 契約を変える時は、描画ロジックとドキュメントを同時に更新する

## Git / GitHub
- メインブランチ: `main`
- 機能追加は `codex/` プレフィックス付きブランチで作業
- PR は `gh pr create` で作成済みワークフロー
