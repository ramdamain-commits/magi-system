# MAGI System

MAGI System は、3つの価値観を持つ AI パネルに同じ問いを審議させ、重要な判断の blind spot を見つけるための実験的な意思決定 UI です。`DEMO`、`GEMINI`、`LOCAL AI`（実験的）の 3 モードを持ち、無料の疑似審議、1 回の Gemini リクエストで返す実AI審議、ブラウザ内ローカルLLM審議を切り替えられます。再審議ループと差分比較で繰り返し遊べるゲーム性を持ち、合議は UI 側で合成します。

## 開発目的

このアプリは、もともと UI と API 連携を素早く作り切るためのバイブコーディング実験として始まりました。今後はそこから一段進めて、以下を主目的に据えます。

- すぐ満場一致になる便利ツールではなく、意図的に意見が割れる審議体験を作る
- 結論だけでなく、反対理由、最大リスク、条件付きの賛成を読み取れるようにする
- 人間が最終判断するための「考える材料」を増やす
- API 上限に潰されず、繰り返し遊べる審議ループを作る

## 現在のプロダクト方針

- `BALTHASAR` は前提破壊担当。常識、権威、楽観を疑う
- `CASPAR` は被害監査担当。権利侵害、炎上、悪用、弱者への影響を見る
- `MELCHIOR` は執行責任担当。実装、運用、責任、撤退計画を見る
- 各パネルは `結論 / 理由 / 最大リスク / 承認条件 / 判定` を UI 上で固定表示する
- 合議結果は `多数決` だけで終わらせず、`少数意見`、`保留条件`、`推奨アクション` まで表示する
- 良い問いは「利害がぶつかる問い」。倫理、利益、運用が衝突するテーマを歓迎する

## API 負荷軽減方針

- 1 回の問いにつき、外部 API 呼び出しは原則 1 回に抑える
- モデルには 3 人格分の審議だけを返させ、合議結果は UI がローカルで `B -> C -> M -> CONSENSUS` の順に合成する
- 出力は JSON 形式の短い構造化レスポンスに限定し、`理由` は最大 1 件、`承認条件` は最大 1 件に抑える
- `RESET` では進行中のリクエストを中断し、無駄な消費を止める
- `DEMO` は API を使わず、疑似審議で割れ方を体験するための無料フォールバックとする
- 将来的な追加策として、ローカル再生キャッシュと必要時のみの少数意見再生成を検討する

## 使い方

1. まず `RUN MODE` で `DEMO`、`GEMINI`、`LOCAL AI` のいずれかを選ぶ
2. `GEMINI` を使う場合だけ、[Google AI Studio](https://aistudio.google.com) で取得した API キーを `API KEY` 欄に入力する
3. テンプレートチップをクリックするか、利害が割れそうな問いを入力して `START` を押す
4. 各パネルの `理由 / 最大リスク / 承認条件 / 判定` を見比べる
5. 最後に `MAJORITY VIEW / MINORITY VIEW / HOLD CONDITIONS / RECOMMENDED ACTION` を読む
6. `再審議` ボタンで同じ問いを繰り返し実行し、前回との差分を比較できる

## 実行モード

- `DEMO`: 無料、キー不要。ブラウザ内の疑似審議で、割れ方と UI の流れを試せる
- `GEMINI`: 実AIモード。1 回の Gemini 呼び出しで 3 人格の審議をまとめて返す
- `LOCAL AI`（実験的）: 無料、キー不要、WebGPU必須。ブラウザ内で小型LLM（Qwen2.5-3B）を実行する。品質基準を満たせない場合は DEMO に自動フォールバックする

## UI / エラー方針

- 初回導線として、`RUN MODE`、必要なら `API KEY`、`QUERY`、`START` を上から順に配置する
- モバイルでは 3 パネルを縦積みにし、CASPAR / MELCHIOR の本文が潰れないようにする
- 入力エラーや通信エラーは `alert()` ではなく画面内のバナーと入力欄下の案内で示す
- `RESET` は問いを消さずに審議だけを中断し、修正して再実行しやすくする

`LOCAL AI` は実験的モードとして再導入しています。WebLLM + Qwen2.5-3B で panel 個別生成を行い、品質基準未達時は DEMO に自動フォールバックします。過去の PoC 知見は [docs/HANDOFF.md](docs/HANDOFF.md) の `KPT` に残しています。

## 開発ファイル

- `index.html` : 現行アプリ
- `docs/UPDATE_POLICY.md` : 開発目的と更新方針
- `docs/HANDOFF.md` : 別スレッドへ渡すための現状整理と次タスク
- `CHANGELOG.md` : 変更履歴

旧試作の `magi.html` と `magi2.html` は、現行仕様との乖離と競合混入を避けるため削除する。

## 更新ルール

- 演出を崩さずに、審議の対立と読みやすさを優先する
- パネル人格を変える時は、UI 表示文言とプロンプトを同時に更新する
- 出力フォーマットや通信方式を変える時は、描画ロジックとドキュメントも一緒に更新する
- 機能変更時は `README.md`、`CHANGELOG.md`、関連ドキュメントの更新要否を必ず確認する
- ドキュメントと GitHub PR は原則として日本語で書く
- テキストの文字コードは `.editorconfig` を正とし、Markdown と PowerShell は UTF-8 BOM、その他のテキストは UTF-8 を基本にする
- GitHub PR は `.github/pull_request_template.md` を使い、必要なら `C:\Users\ramda\projects\setting\Run-GitHubPrCreate.cmd` を使って本文ファイルを UTF-8 で生成する
- PR では `.github/workflows/text-encoding-check.yml` が `scripts/Test-TextEncoding.ps1 -Recurse -FailOnWarning` を実行する

詳細方針は [docs/UPDATE_POLICY.md](docs/UPDATE_POLICY.md) を参照してください。
