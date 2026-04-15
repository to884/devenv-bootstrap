# Ansible 開発環境セットアップ

このディレクトリには、Linux開発環境を自動的にセットアップするためのAnsible playbookが含まれています。

## 📋 概要

以下のタスクを自動化します:

1. **sudoers 設定**
   - プロキシ環境変数の保持 (`http_proxy`, `https_proxy`, `ftp_proxy`, `all_proxy`, `no_proxy`)
   - `EDITOR` 環境変数の保持
   - `sudo` グループにパスワードなしsudo権限を付与

2. **Zscalerルート証明書の確認** (オプション)
   - `$HOME/.certs/ZscalerRootCA.crt` の存在をチェックし、フラグを設定
   - **注**: 証明書のインストールは `bootstrap.sh` で既に実施済み
   - 証明書が存在しない場合は自動スキップ

3. **共通パッケージインストール**
   - 基本的な開発ツール (git, curl, wget, vim, htop)
   - Linuxbrew本体のインストール

4. **topgrade インストール**
   - パッケージ一括更新ツール topgrade (Linuxbrew経由)
   - Docker環境では自動スキップ

5. **uv インストール**
   - 高速Pythonパッケージインストーラー uv および uvx (Linuxbrew経由)
   - Rustベースの次世代Pythonツール

6. **Node.js インストール**
   - Node.js、npm、npx (Linuxbrew経由)
   - JavaScriptランタイムとパッケージマネージャー

7. **starship インストール**
   - 高速でカスタマイズ可能なシェルプロンプト (Linuxbrew経由)
   - Rustベースのクロスシェル対応プロンプト

8. **bat インストール**
   - 構文ハイライト機能付きcatの改良版 (Linuxbrew経由)
   - Git統合、行番号表示、ページング機能

9. **git-delta インストール**
   - Git差分の構文ハイライトツール (Linuxbrew経由)
   - より読みやすいgit diff表示

10. **GitHub CLI (gh) インストール**
   - GitHubの公式コマンドラインツール (Linuxbrew経由)
   - リポジトリ操作、issue管理、PR作成などをCLIから実行

11. **GitHub Copilot CLI インストール**
   - AI搭載のコマンドライン支援ツール (Linuxbrew経由)
   - シェルコマンド、Git操作の提案、コマンドの説明

12. **Databricks CLI インストール**
   - Databricks ワークスペース管理ツール (Linuxbrew経由)
   - クラスター、ジョブ、ワークスペースの管理をCLIから実行

13. **eza インストール**
   - lsコマンドの現代的な代替ツール (Linuxbrew経由)
   - アイコン表示、Git統合、ツリー表示

14. **シェル設定の適用**
   - .bashrc, .bash_profile, .profile, .zshrc の設定
   - Linuxbrew shellenv の追加（PATH等の環境変数）
   - starship プロンプトの初期化
   - .curlrc に Zscaler証明書設定（証明書が存在する場合）

15. **chezmoi インストール**
   - ドットファイル管理ツール chezmoi (Linuxbrew経由)
   - ツールのインストールのみ（dotfiles の適用は手動）
   - 複数マシン間での設定ファイル同期に便利

16. **xh インストール**
   - HTTPクライアントツール (Linuxbrew経由)
   - curlやhttpieの代替、Rust製で高速

17. **tmux インストール**
   - ターミナルマルチプレクサ (Linuxbrew経由)
   - 複数のシェルセッションを管理、Powerline統合

18. **Docker インストール**
   - Docker Engine の公式スクリプト経由インストール
   - ユーザーを docker グループに追加
   - Docker環境では自動スキップ

19. **SSH設定**
   - OpenSSH serverのインストールと設定
   - systemdサービスの有効化

19. **環境固有の設定**
   - WSL: /etc/wsl.conf の設定、systemd有効化
   - Azure VM: Azure CLI のインストール
   - EC2: AWS CLI v2 のインストール
   - Hyper-V: 統合サービスのインストール
   - ベアメタル: ハードウェア情報の表示
   - Docker: コンテナ環境の検出

## 🚀 クイックスタート

### 前提条件

Ansibleがインストールされている必要があります。`bootstrap.sh` を使ってインストールできます:

```bash
# リポジトリのルートディレクトリで実行
./bootstrap.sh
source ~/.ansible-venv/bin/activate
```

### dotfiles管理方法

`group_vars/all.yml` でリポジトリに含まれる dotfiles の自動適用を制御します：

```yaml
# このリポジトリの dotfiles を chezmoi で自動適用する場合は true に設定
chezmoi_auto_apply: true  # デフォルト: 自動適用（推奨）
```

**デフォルトでは dotfiles を自動適用します** (推奨設定):

```bash
# Ansibleでシステム基盤とパッケージをインストール
cd ansible
ansible-playbook -i inventories/wsl/hosts site.yml

# chezmoi が自動的に dotfiles を初期化・適用します
# （bootstrap playbook 内で自動実行されます）
```

chezmoiによって管理されるファイル:
- `~/.bashrc`, `~/.zshrc` - シェル設定（Linuxbrew、starship初期化）
- `~/.gitconfig` - Git設定（delta、エイリアス）
- `~/.tmux.conf` - tmux設定
- `~/.config/starship.toml` - starshipプロンプト設定
- `~/.config/powerline/` - Powerline設定
- `~/.ssh/config` - SSH設定

### 実行方法

環境に応じたインベントリファイルを指定して実行します。

#### 🆕 環境別専用playbook（推奨）

各環境に特化したplaybookを使用する方法（新機能）:

```bash
# ansibleディレクトリに移動
cd ansible

# WSL環境専用 - より明確で確実
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap-wsl.yml

# Azure VM環境専用 - Azure CLIも自動インストール
ansible-playbook -i inventories/azure-vm/hosts playbooks/bootstrap-azure-vm.yml

# EC2環境専用 - AWS CLIも自動インストール
ansible-playbook -i inventories/ec2/hosts playbooks/bootstrap-ec2.yml

# Hyper-V環境専用
ansible-playbook -i inventories/hyperv/hosts playbooks/bootstrap-hyperv.yml

# ベアメタル環境専用
ansible-playbook -i inventories/baremetal/hosts playbooks/bootstrap-baremetal.yml

# Docker環境専用
ansible-playbook -i inventories/docker/hosts playbooks/bootstrap-docker.yml
```

**環境別playbookのメリット**:
- ✅ **明確性**: 実行対象環境が一目で分かる
- ✅ **安全性**: 環境タイプの自動チェック機能内蔵
- ✅ **環境固有メッセージ**: 各環境に最適化された完了メッセージ
- ✅ **デバッグ容易**: 環境固有の問題を切り分けやすい

#### 従来の汎用playbook（後方互換）

従来通りの汎用playbookも引き続き利用可能です:

```bash
# WSL環境の場合
ansible-playbook -i inventories/wsl/hosts site.yml

# Azure VM環境の場合
ansible-playbook -i inventories/azure-vm/hosts site.yml

# EC2環境の場合
ansible-playbook -i inventories/ec2/hosts site.yml

# Hyper-V環境の場合
ansible-playbook -i inventories/hyperv/hosts site.yml

# ベアメタル環境の場合
ansible-playbook -i inventories/baremetal/hosts site.yml

# Docker環境の場合
ansible-playbook -i inventories/docker/hosts site.yml
```

または、統合ブートストラップ（bootstrap.yml）も利用可能:

```bash
# 統合版ブートストラップ（全環境対応）
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml
ansible-playbook -i inventories/azure-vm/hosts playbooks/bootstrap.yml
ansible-playbook -i inventories/ec2/hosts playbooks/bootstrap.yml
```

## 📖 詳細な使用方法

### Dry-run モード（変更を確認のみ）

実際に変更を行わずに、何が実行されるか確認できます:

```bash
ansible-playbook -i inventories/wsl/hosts site.yml --check
```

### 詳細ログを表示

```bash
# 通常の詳細ログ
ansible-playbook -i inventories/wsl/hosts site.yml -v

# より詳細なログ
ansible-playbook -i inventories/wsl/hosts site.yml -vv

# 最も詳細なログ（デバッグ用）
ansible-playbook -i inventories/wsl/hosts site.yml -vvv
```

### 特定のタスクのみ実行

タグを使用して、特定のロールのみを実行できます:

```bash
# sudoers設定のみ
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags sudo

# 共通パッケージのみ
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags common

# topgradeのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags topgrade

# uvのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags uv

# Node.jsのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags node

# starshipのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags starship

# batのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags bat

# git-deltaのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags delta

# GitHub CLIのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags gh

# GitHub Copilot CLIのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags copilot_cli

# Databricks CLIのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags databricks_cli

# ezaのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags eza

# chezmoiのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags chezmoi

# xhのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags xh

# tmuxのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags tmux

# Dockerのみインストール
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags docker

# SSH設定のみ
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags ssh

# WSL固有設定のみ
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags wsl
```

### 特定のタスクをスキップ

```bash
# sudoers設定をスキップ
ansible-playbook -i inventories/wsl/hosts site.yml --skip-tags sudo

# SSH設定をスキップ
ansible-playbook -i inventories/wsl/hosts site.yml --skip-tags ssh
```

### ブートストラップのみ実行

```bash
# 環境別ブートストラップ
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml
```

### コンテナ環境専用セットアップ

```bash
# Docker環境専用
ansible-playbook -i inventories/docker/hosts playbooks/containers.yml
```

## 📁 プロジェクト構造

```
ansible/
├── ansible.cfg                      # Ansible設定ファイル
├── site.yml                         # メインエントリーポイント
├── group_vars/
│   └── all.yml                      # 全ホスト共通の変数定義
├── inventories/                     # 環境別インベントリディレクトリ
│   ├── wsl/
│   │   └── hosts                    # WSL環境用インベントリ
│   ├── azure-vm/
│   │   └── hosts                    # Azure VM環境用インベントリ
│   ├── ec2/
│   │   └── hosts                    # EC2環境用インベントリ
│   ├── hyperv/
│   │   └── hosts                    # Hyper-V環境用インベントリ
│   ├── baremetal/
│   │   └── hosts                    # ベアメタル環境用インベントリ
│   └── docker/
│       └── hosts                    # Docker環境用インベントリ
├── playbooks/
│   ├── bootstrap.yml                # 統合ブートストラップPlaybook（後方互換）
│   ├── containers.yml               # コンテナ環境専用Playbook
│   ├── bootstrap-wsl.yml            # 🆕 WSL環境専用Playbook
│   ├── bootstrap-azure-vm.yml       # 🆕 Azure VM環境専用Playbook
│   ├── bootstrap-ec2.yml            # 🆕 EC2環境専用Playbook
│   ├── bootstrap-hyperv.yml         # 🆕 Hyper-V環境専用Playbook
│   ├── bootstrap-baremetal.yml      # 🆕 ベアメタル環境専用Playbook
│   ├── bootstrap-docker.yml         # 🆕 Docker環境専用Playbook
│   └── includes/                    # 🆕 共通playbook格納ディレクトリ
│       └── common-setup.yml         # 🆕 全環境共通セットアップ
└── roles/
    ├── sudo/                        # sudoers設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── common/                      # 共通パッケージロール
    │   └── tasks/
    │       ├── main.yml
    │       └── linuxbrew.yml
    ├── topgrade/                    # topgradeインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── uv/                          # uvインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── node/                        # Node.jsインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── starship/                    # starshipインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── bat/                         # batインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── docker_install/              # Dockerインストールロール
    │   └── tasks/
    │       └── main.yml
    ├── ssh/                         # SSH設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── wsl/                         # WSL固有設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── azure_vm/                    # Azure VM固有設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── ec2/                         # EC2固有設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── hyperv/                      # Hyper-V固有設定ロール
    │   └── tasks/
    │       └── main.yml
    ├── baremetal/                   # ベアメタル固有設定ロール
    │   └── tasks/
    │       └── main.yml
    └── docker/                      # Docker固有設定ロール
        └── tasks/
            └── main.yml
```

## 🔍 各ロールの詳細

### sudo ロール

**目的**: sudoersファイルを安全に編集し、開発環境に適した設定を追加

**実行内容**:
- `/etc/sudoers.d/` ディレクトリに設定ファイルを作成
- `visudo` で構文チェックを実行（安全性確保）
- 以下の3つの設定ファイルを作成:
  - `90-env-keep-proxy`: プロキシ環境変数の保持
  - `90-env-keep-editor`: EDITOR環境変数の保持
  - `90-sudo-nopasswd`: パスワードなしsudo権限

**注意事項**:
- このロールは `become: yes` (sudo権限) が必要です
- `/etc/sudoers.d/` 内のファイルは自動的に読み込まれます
- 設定ファイルは `0440` のパーミッション（読み取り専用）で作成されます

### common ロール

**目的**: 共通パッケージとLinuxbrewをインストール

**実行内容**:
1. 基本パッケージのインストール (git, curl, wget, vim, htop)
2. ディストリビューションに応じた依存パッケージのインストール
3. 公式インストールスクリプトを使用したLinuxbrewインストール

※ シェル設定ファイル (`.bashrc`, `.zshrc`) への PATH 追加は chezmoi で管理されます

**対応ディストリビューション**:
- Ubuntu/Debian (apt)
- RHEL/CentOS/Fedora (dnf)
- Arch Linux (pacman)

**インストール後**:

新しいシェルセッションを開始するか、以下を実行:
```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

動作確認:
```bash
brew --version
```

### topgrade ロール

**目的**: パッケージ一括更新ツール topgrade をインストール

**実行内容**:
- Linuxbrew 経由で topgrade をインストール
- brew、apt、dnf、pipなど複数のパッケージマネージャーを一括更新

**前提条件**:
- Linuxbrew がインストール済みであること

**注意事項**:
- Docker環境ではインストールをスキップします（コンテナの性質上不要なため）

**インストール後**:

topgradeの動作確認:
```bash
topgrade --version
```

使用例:
```bash
# すべてのパッケージマネージャーを更新
topgrade

# Dry-runモード
topgrade --dry-run
```

### uv ロール

**目的**: 高速Pythonパッケージインストーラー uv および uvx をインストール

**実行内容**:
- Linuxbrew 経由で uv をインストール
- uv: 超高速なPythonパッケージ＆プロジェクト管理ツール
- uvx: パッケージを一時的にインストールしてツールを実行

**前提条件**:
- Linuxbrew がインストール済みであること

**特徴**:
- pipやpoetryよりも10-100倍高速
- Rustで実装された次世代Pythonツール
- 仮想環境の作成、パッケージ管理、ツール実行を一元化

**インストール後**:

動作確認:
```bash
# バージョン確認
uv --version

# Pythonパッケージをインストール
uv pip install requests

# 仮想環境を作成
uv venv

# ツールを一時実行（uvx）
uvx ruff check .
uvx black --check .
```

使用例:
```bash
# プロジェクトの依存関係をインストール
uv pip install -r requirements.txt

# 高速な仮想環境作成
uv venv .venv
source .venv/bin/activate

# ツールを直接実行（インストール不要）
uvx pytest
uvx mypy src/
```

### node ロール

**目的**: Node.js、npm、npx をインストール

**実行内容**:
- Linuxbrew 経由で Node.js をインストール
- npm: Node.js パッケージマネージャー（node に含まれる）
- npx: Node.js パッケージ実行ツール（node に含まれる）

**前提条件**:
- Linuxbrew がインストール済みであること

**特徴**:
- 最新の Node.js LTS バージョンをインストール
- npm と npx が自動的に含まれる
- グローバルパッケージの管理が容易

**インストール後**:

動作確認:
```bash
# バージョン確認
node --version
npm --version
npx --version
```

使用例:
```bash
# プロジェクトを初期化
npm init -y

# パッケージをインストール
npm install express
npm install --save-dev typescript

# グローバルインストール
npm install -g yarn pnpm

# npx でパッケージを一時実行
npx create-react-app my-app
npx prettier --write .
npx eslint --init

# スクリプト実行
npm run dev
npm test
```

### starship ロール

**目的**: 高速でカスタマイズ可能なシェルプロンプト starship をインストール

**実行内容**:
- Linuxbrew 経由で starship をインストール
- Rustベースの次世代シェルプロンプト

※ シェル初期化設定 (`.bashrc`, `.zshrc`) と設定ファイル (`~/.config/starship.toml`) は chezmoi で管理されます

**前提条件**:
- Linuxbrew がインストール済みであること

**特徴**:
- 超高速: Rustで実装され、遅延なく表示
- クロスシェル対応: bash、zsh、fish、PowerShellなどで動作
- カスタマイズ可能: TOML設定ファイルで簡単にカスタマイズ
- Git統合: ブランチ、ステータスを自動表示
- プログラミング言語の検出: プロジェクト内の言語バージョンを表示

**インストール後**:

**インストール後**:

新しいシェルセッションを開始するか、以下を実行:
```bash
source ~/.bashrc
```

動作確認:
```bash
# バージョン確認
starship --version
```

**設定ファイルの管理**:

chezmoi によって `~/.config/starship.toml` に実用的な設定ファイルが配置されます。
この設定には以下が含まれています:
- Git ブランチとステータス表示
- Python、Node.js、Rustなどの言語バージョン表示
- Docker、Kubernetes コンテキスト表示
- AWS、Azure などのクラウド環境表示
- コマンド実行時間の表示
- カスタムプロンプトフォーマット

カスタマイズ:
```bash
# 設定ファイルを編集（chezmoi経由）
chezmoi edit ~/.config/starship.toml

# プリセット一覧を表示
starship preset

# 別のプリセットを適用（設定を上書き）
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

使用例:
```bash
# プロジェクトディレクトリに移動すると自動的に情報を表示
cd my-python-project  # Python バージョンが表示される
cd my-node-project    # Node.js バージョンが表示される
cd my-git-repo        # Git ブランチとステータスが表示される
```

公式サイト: https://starship.rs/

### databricks_cli ロール

**目的**: Databricks CLI をインストール

**実行内容**:
- Linuxbrew 経由で Databricks CLI をインストール
- Databricks ワークスペース、クラスター、ジョブの管理ツール

**前提条件**:
- Linuxbrew がインストール済みであること

**特徴**:
- Databricks ワークスペースの管理: ノートブック、ジョブ、クラスターをCLIから操作
- 認証管理: トークンベースの認証をサポート
- バンドル機能: アセットのバンドル化とデプロイを自動化
- REST API統合: Databricks の全機能にアクセス可能

**インストール後**:

動作確認:
```bash
# バージョン確認
databricks --version
```

使用例:
```bash
# 認証設定（対話的）
databricks configure --token

# ワークスペース一覧を取得
databricks workspace list /

# クラスター一覧を表示
databricks clusters list

# ジョブ一覧を表示
databricks jobs list

# ノートブックをエクスポート
databricks workspace export /Users/user@example.com/notebook notebook.py

# ノートブックをインポート
databricks workspace import notebook.py /Users/user@example.com/notebook

# バンドルの検証
databricks bundle validate

# バンドルのデプロイ
databricks bundle deploy
```

設定ファイル:
```bash
# 認証情報は ~/.databrickscfg に保存されます
cat ~/.databrickscfg
```

公式サイト: https://docs.databricks.com/dev-tools/cli/index.html

### bat ロール

**目的**: 構文ハイライト機能付きcatの改良版 bat をインストール

**実行内容**:
- Linuxbrew 経由で bat をインストール
- 構文ハイライト、行番号表示、Git統合を備えた高機能テキスト表示ツール

**前提条件**:
- Linuxbrew がインストール済みであること

**特徴**:
- シンタックスハイライト: 多数のプログラミング言語に対応
- Git統合: 変更箇所をハイライト表示
- 行番号表示: ファイルの行番号を自動表示
- ページング機能: 長いファイルを自動的にページング
- 非印字文字の表示: タブや改行を可視化

**インストール後**:

動作確認:
```bash
# バージョン確認
bat --version
```

使用例:
```bash
# ファイルを表示（構文ハイライト付き）
bat script.py
bat config.yaml
bat README.md

# 特定の行範囲を表示
bat --line-range 1:20 file.txt
bat --line-range :50 file.txt

# Git差分を表示
bat --diff file.txt

# テーマを変更
bat --theme=GitHub script.js

# テーマ一覧を表示
bat --list-themes

# catの代わりに使用（エイリアス設定）
echo 'alias cat="bat"' >> ~/.bashrc
source ~/.bashrc
```

便利な使い方:
```bash
# 複数ファイルを連結表示
bat file1.py file2.py file3.py

# プレーンテキストモード（装飾なし）
bat --plain file.txt

# 行番号なし
bat --style=plain file.txt
```

公式サイト: https://github.com/sharkdp/bat

### docker_install ロール

**目的**: Docker Engine をインストール

**実行内容**:
- Docker 公式インストールスクリプトを使用した Docker Engine のインストール
- 現在のユーザーを docker グループに追加
- Docker サービスの起動と有効化

**対応ディストリビューション**:
- Ubuntu/Debian (apt)
- RHEL/CentOS/Fedora (dnf/yum)
- Arch Linux (pacman)
- その他（公式スクリプトが対応するすべてのディストリビューション）

**注意事項**:
- Docker環境ではインストールをスキップします（既にDockerコンテナ内のため）
- docker グループへの追加を反映するには、ログアウト/再ログインまたは `newgrp docker` が必要

**インストール後**:

動作確認:
```bash
# バージョン確認
docker --version

# Hello Worldコンテナを実行
docker run hello-world

# Docker Composeのインストール（必要な場合）
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

グループ変更の反映:
```bash
# 方法1: 新しいグループセッションを開始
newgrp docker

# 方法2: ログアウト/再ログイン
```

### ssh ロール

**目的**: OpenSSH serverのインストールと設定

**実行内容**:
- openssh-server パッケージのインストール
- sshd サービスの起動と有効化
- systemd によるサービス管理

### 環境固有ロール

#### wsl ロール

**対象**: WSL (Windows Subsystem for Linux) 環境

**実行内容**:
- `/etc/wsl.conf` の設定
- systemd の有効化
- ネットワーク設定（hostname生成の無効化）
- Windows相互運用の設定

#### azure_vm ロール

**対象**: Azure Virtual Machines

**実行内容**:
- Azure CLI のインストール
- Linuxbrew が存在する場合は `brew install azure-cli` を優先使用
- Linuxbrew がない場合は公式スクリプトを使用
- Debian系（Ubuntu/Debian）およびRHEL系（RHEL/CentOS/Fedora）に対応

#### ec2 ロール

**対象**: AWS EC2インスタンス

**実行内容**:
- AWS CLI のインストール
- Linuxbrew が存在する場合は `brew install awscli` を優先使用
- Linuxbrew がない場合は AWS CLI v2 公式インストーラーを使用

#### hyperv ロール

**対象**: Hyper-V仮想マシン

**実行内容**:
- linux-virtual パッケージのインストール
- Hyper-V統合サービスの有効化

#### baremetal ロール

**対象**: 物理サーバー（ベアメタル）

**実行内容**:
- ハードウェア情報の表示
  - CPU情報
  - メモリ情報
  - アーキテクチャ情報

#### docker ロール

**対象**: Dockerコンテナ環境

**実行内容**:
- `/.dockerenv` ファイルの存在チェック
- コンテナ環境の検出と確認

## 🔒 セキュリティ

- sudoers設定は `/etc/sudoers.d/` に分離して配置
- すべてのsudoers設定ファイルは `visudo -c` で構文チェック
- ファイルパーミッションは `0440` (root:root, 読み取り専用)
- Linuxbrewは非root権限でインストール

## 🐛 トラブルシューティング

### Ansibleが見つからない

```bash
# 仮想環境を有効化
source ~/.ansible-venv/bin/activate
```

### sudo権限エラー

Playbookは一部のタスクでsudo権限が必要です。パスワードを求められた場合:

```bash
ansible-playbook -i inventories/wsl/hosts site.yml --ask-become-pass
```

### Linuxbrewのインストールが失敗する

依存パッケージが不足している可能性があります。手動で確認:

```bash
# Ubuntu/Debian
sudo apt install build-essential procps curl file git

# RHEL/Fedora
sudo dnf install gcc gcc-c++ make procps-ng curl file git

# Arch
sudo pacman -S base-devel procps-ng curl file git
```

### べき等性の確認

Playbookを2回実行して、変更が発生しないことを確認:

```bash
ansible-playbook -i inventories/wsl/hosts site.yml
ansible-playbook -i inventories/wsl/hosts site.yml  # 2回目は変更なし (changed=0)
```

### インベントリファイルの選択ミス

環境に合わせて正しいインベントリファイルを指定してください:

- WSL環境: `-i inventories/wsl/hosts`
- Azure VM: `-i inventories/azure-vm/hosts`
- EC2: `-i inventories/ec2/hosts`
- Hyper-V: `-i inventories/hyperv/hosts`
- ベアメタル: `-i inventories/baremetal/hosts`
- Docker: `-i inventories/docker/hosts`

### 構文チェック

Ansibleをインストール後、構文チェックが可能です:

```bash
# Playbook構文チェック
ansible-playbook -i inventories/wsl/hosts site.yml --syntax-check

# インベントリ確認
ansible-inventory -i inventories/wsl/hosts --list
```

## 🔄 Ansibleとchezmoiの使い分け

### 管理方法の選択

`group_vars/all.yml` でリポジトリに含まれる dotfiles の自動適用を制御できます：

```yaml
# このリポジトリの dotfiles を chezmoi で自動適用する場合は true に設定
# false の場合、chezmoi ツールはインストールされますが dotfiles の初期化・適用はスキップされます
chezmoi_auto_apply: true  # デフォルト: 自動適用（推奨）
```

### 推奨構成: ハイブリッドアプローチ（デフォルト）

**Ansible**: システム基盤とパッケージのインストール  
**chezmoi**: 個人設定ファイル（dotfiles）の管理

※ `chezmoi_auto_apply: true` がデフォルト設定です

#### Ansibleが管理するもの

✅ **パッケージインストール**
- Linuxbrew本体
- CLIツール（bat、delta、eza、gh、chezmoi等）
- ランタイム（Node.js、uv）
- Docker Engine

✅ **システム設定**
- sudoers設定
- SSHサーバーのインストールと起動
- 環境固有の設定（WSL、Azure VM、EC2等）

#### chezmoiが管理するもの（推奨）

✅ **個人設定ファイル**
- シェル設定（~/.bashrc、~/.zshrc）
- Git設定（~/.gitconfig）
- ターミナル設定（~/.tmux.conf）
- プロンプト設定（~/.config/starship.toml）
- PowerLine設定（~/.config/powerline/）

### ワークフロー

```bash
# 手顺1: Ansibleでシステム基盤を構築（chezmoiが自動的のdotfilesを適用）
cd ansible
ansible-playbook -i inventories/wsl/hosts site.yml

# 手顺2: （オプション）chezmoiで追加のカスタマイズ
# 変更内容を確認
chezmoi diff

# 設定を編集
chezmoi edit ~/.bashrc

# 変更を適用
chezmoi apply -v
```

### 利点

- **明確な責任分離**: システム構築と個人設定を分離
- **柔軟性**: 個人設定だけを別マシンに適用可能
- **バージョン管理**: dotfilesを独立したリポジトリで管理
- **頻繁な変更に対応**: 個人設定の変更がシステム構築に影響しない

詳細は [`dotfiles/README.md`](../dotfiles/README.md) を参照してください。

## 📚 参考資料

- [Ansible Documentation](https://docs.ansible.com/)
- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)
- [sudoers Manual](https://www.sudo.ws/docs/man/sudoers.man/)
- [chezmoi Documentation](https://www.chezmoi.io/)
