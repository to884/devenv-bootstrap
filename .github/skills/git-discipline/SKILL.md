---
name: git-discipline
description: >
  Enforce consistent Git discipline across branches, commits, and pull requests.
  Use this skill when creating branches, writing commit messages, preparing pull
  requests, or reviewing Git history quality.
license: CC-BY-4.0
compatibility: >
  Compatible with GitHub Copilot, Copilot Coding Agent, Copilot CLI,
  VS Code Agent Mode, Claude Code, and other agents supporting Agent Skills.
metadata:
  category: git
  maturity: stable
  audience:
    - professional-teams
    - open-source
    - enterprise
  philosophy:
    - git-history-as-documentation
    - correctness-over-convenience
  enforced-standards:
    - conventional-commits
    - semantic-branch-naming
---

# Git Discipline スキル

このスキルは、開発ワークフロー全体を通じて**高品質で一貫したGitプラクティス**を
適用します。

エージェントは、正確性と可読性と並んで、Git履歴の品質を最優先事項として
扱わなければなりません。

---

## このスキルの適用範囲

以下のいずれかを含むタスクの場合、このスキルを適用してください:

- Gitブランチ名の作成または提案
- コミットメッセージの記述または修正
- コミットの分割またはスカッシュ
- プルリクエストの準備
- Git履歴またはdiffのレビュー

---

## 1. ブランチ命名規則

### ルール

すべてのブランチ名は、以下の形式に従わなければなりません:

```
<type>/<short-description></short-description></type>
```

### 許可されるタイプ

- ✨ feature（新機能）
- 🐛 fix（バグ修正）
- 🚑 hotfix（緊急修正）
- ♻️ refactor（リファクタリング）
- 🔧 chore（雑務）
- 📝 docs（ドキュメント）
- ✅ test（テスト）

### 命名ルール

- 小文字のみを使用すること
- 単語の区切りにはハイフン（`-`）を使用すること
- 説明は簡潔に保つこと（最大5〜7単語）
- 明示的に要求されない限り、issue番号を含めないこと

### 例

✅ 正しい例:

`feature/add-user-auth`
`fix/handle-null-response`
`docs/update-readme`

❌ 誤った例:
`Feature/AddUserAuth`
`bugfix_login_issue`
`feature/1234-add-auth`


### エージェントの動作

- Gitコマンドを生成する際は、常に準拠したブランチ名を提案すること
- 非準拠の名前が検出された場合は、修正案を提示すること

---

## 2. Conventional Commits

### ルール

すべてのコミットメッセージは、Conventional Commits形式に従わなければなりません:

```
<type>(<scope>): <description></description></scope></type>
```

### 許可されるタイプ

- ✨ feat: 新機能
- 🐛 fix: バグ修正
- 📝 docs: ドキュメントのみの変更
- 💄 style: フォーマット、リント（ロジック変更なし）
- ♻️ refactor: 振る舞いを変えない内部リファクタリング
- ⚡ perf: パフォーマンス改善
- ✅ test: テストの追加または修正
- 🔧 chore: ビルド、CI、ツール、依存関係の更新

### スコープのルール

- スコープは任意（OPTIONAL）
- 使用する場合、スコープは論理的なモジュールまたはドメインを表すこと
- ファイル名をスコープとして使用しないこと

### 説明のルール

- 命令形を使用すること（例: "add"、"added"ではない）
- 小文字で始めること
- ピリオドで終わらないこと

### 例

✅ 正しい例:

`feat(auth): add token refresh logic`
`fix(api): handle null error response`
`chore(ci): update workflow timeout`

❌ 誤った例:

`Fixed login bug`
`feat: Added new feature.`
`fix(login_bug)`

### エージェントの動作

- 常にこの形式でコミットメッセージを提案すること
- 非準拠のコミットメッセージは書き直すか却下すること
- 必要に応じて、簡潔さよりも明確さを優先すること

---

## 3. コミットタイプの正確性

### ルール

エージェントは、コミットの意図を正確に判断しなければなりません。

### ガイドライン

| 状況 | コミットタイプ |
|---------|------------|
| 新しい外部動作またはAPI | feat |
| 機能追加を伴わないバグ修正 | fix |
| 振る舞いを保持する改善 | refactor |
| 内部メンテナンス / クリーンアップ | chore |
| パフォーマンスのみの改善 | perf |

### 曖昧さ解消のルール

`feat`と`fix`のどちらか判断に迷う場合:

> 新しい外部向けの振る舞いが導入されない限り、**fix**をデフォルトとすること。

### エージェントの動作

- コミットを提案する際は、選択したタイプの理由を簡潔に説明すること
- `feat`の過剰使用を避けること

---

## 4. コミットの粒度

### ルール

- 1コミットにつき1つの論理的な変更
- リファクタリングと機能変更を混在させないこと

### エージェントの動作

- 小さく焦点を絞った複数のコミットを優先すること
- 無関係な変更が検出された場合は、コミットの分割を提案すること
- 共有ブランチや保護されたブランチでは"WIP"コミットを避けること

---

## 5. プルリクエスト規約

### PRタイトル

- Conventional Commits形式に従わなければならない
- 主要なコミットタイプと整合させること

### PR説明テンプレート

エージェントは`.github/pull_request_template.md`をテンプレートとして使用し、
変更内容に基づいて**各セクションを積極的に記入**すること。

#### テンプレートの使用方法

- リポジトリのpull_request_template.mdを基本構造として使用すること
- GitHub Copilotはテンプレートの各セクションを知的に埋めること:
  - **変更対象**: 何が変更されたかを要約
  - **変更理由**: なぜ変更が必要だったかを説明
  - **変更方法**: 実装の概要を提供
  - **テスト**: 該当するテスト項目をチェック
  - **チェックリスト**: 完了したチェックリスト項目にマーク
  - **関連**: 関連するissueやチケットへのリンク（該当する場合）

#### 最小限必要な構造

テンプレートが利用できない場合は、このフォールバック構造を使用すること:

```
## 変更対象
- 何が変更されたか

## 変更理由
- なぜ変更が必要だったか

## 変更方法
- 実装の概要

## 関連
- 関連するissueやチケット（任意）
```

### エージェントの動作

- PRタイトルがコミット履歴と整合していることを確認すること
- PRタイトルとコミット間の不一致を指摘すること
- コード変更とコミットに基づいてテンプレートセクションを積極的に記入すること
- pull_request_template.mdを使用する際は、すべての関連セクションを埋めること
- 行われた変更に基づいて、該当するチェックリスト項目にマークすること

---

## 6. ブランチ戦略と履歴戦略

### ルール

- 短命なブランチを優先すること
- 明示的に指示されない限り、マージよりもリベースを優先すること
- 可能な限りクリーンで直線的な履歴を維持すること

### エージェントの動作

- マージコミットが価値を追加しない場合は、リベースを提案すること
- 履歴がノイズで汚れたり不明瞭になった場合は警告すること

---

## 優先順位

意思決定の際、エージェントは以下の順で優先しなければなりません:

1. 正確性
2. 可読性
3. Git履歴の品質

---

## 明示的な制約

- 明示的に要求されない限り、代替のGitワークフローを導入しないこと
- 一般的なベストプラクティスよりもリポジトリ定義のルールに従うこと
- 便宜のためにこれらのルールを緩和しないこと

---

## まとめ

このスキルは**Git規律をコード品質の一部として扱います**。

エージェントは、以下のようなシニアエンジニアとして行動しなければなりません:
- 将来のメンテナーを気にかける
- 履歴をドキュメントとして扱う
- リポジトリを見つけた時よりも良い状態にする
