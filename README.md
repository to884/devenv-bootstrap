# Dev Environment Bootstrap

このリポジトリには、Linux環境でAnsibleを迅速にセットアップするためのブートストラップスクリプトが含まれています。

## 📋 概要

`bootstrap.sh` は、Gitリポジトリをクローンした直後に実行する最初のスクリプトです。複数のLinuxディストリビューションに対応し、Ansibleを安全にインストールします。

## ✨ 特徴

- **クロスディストリビューション対応**: Ubuntu/Debian、RHEL/CentOS/Fedora、Arch Linuxをサポート
- **様々な実行環境で動作**: WSL、Hyper-V、Azure VM、AWS EC2、Docker、ベアメタルサーバー
- **安全なインストール**: システムPythonを汚染しない仮想環境へのインストール
- **防御的プログラミング**: 厳格なエラーハンドリングとクリーンアップ処理
- **Dry-runモード**: 実際の変更前にプレビュー可能
- **詳細ログ**: デバッグモードで詳細な実行ログを出力
- **べき等性**: 繰り返し実行しても安全
- **Zscaler環境対応**: 
  - `$HOME/.certs/ZscalerRootCA.cer` を自動検出
  - DER形式の証明書を自動的にPEM形式に変換
  - システム証明書ストアへの自動追加
  - pipコマンドで証明書を自動適用（SSL証明書検証エラーを回避）

## 🚀 クイックスタート

```bash
# リポジトリをクローン
git clone <repository-url>
cd dev-env-bootstrap

# （Zscaler環境の場合）ルート証明書を配置
# DER形式（.cer）またはPEM形式（.crt/.pem）どちらでも可
mkdir -p ~/.certs
cp /path/to/ZscalerRootCA.cer ~/.certs/

# 1. Ansibleインストール用の仮想環境をセットアップ
# Zscaler証明書が存在する場合:
#   - 自動的に検出・変換・適用されます
#   - 登録後、自動的に検証スクリプトが実行されます
#   - 検証結果がログに表示されます
./bootstrap.sh

# 2. 仮想環境を有効化
source .ansible-venv/bin/activate

# 3. Ansibleでパッケージとツールをインストール
cd ansible
ansible-playbook -i inventories/wsl/hosts site.yml

# 4. （オプション）chezmoiで個人設定を適用
chezmoi init /path/to/devenv-bootstrap/dotfiles
chezmoi apply -v
```

## 🗂 ディレクトリ構成

```
devenv-bootstrap/
├── bootstrap.sh          # Ansibleインストールスクリプト
├── scripts/              # プラットフォーム固有の処理
│   ├── lib/
│   │   └── common.sh    # 共通関数（証明書変換含む）
│   └── platforms/       # プラットフォーム別ハンドラー
├── ansible/              # Ansible playbookとロール
│   ├── site.yml         # メインエントリーポイント
│   ├── playbooks/       # Playbook定義
│   ├── roles/           # ロール（パッケージ、ツールのインストール）
│   ├── inventories/     # 環境別インベントリ（WSL、Azure VM、EC2等）
│   └── group_vars/      # グローバル変数
└── dotfiles/             # chezmoi管理下の個人設定ファイル
    ├── dot_bashrc.tmpl  # ~/.bashrc
    ├── dot_zshrc.tmpl   # ~/.zshrc
    ├── dot_gitconfig.tmpl # ~/.gitconfig
    ├── dot_tmux.conf    # ~/.tmux.conf
    └── dot_config/      # ~/.config/
        ├── starship.toml
        └── powerline/

# Zscaler環境の場合
~/.certs/
└── ZscalerRootCA.cer    # DER形式またはPEM形式の証明書
                         # 自動的にPEM形式に変換され、システム証明書ストアに追加されます
```

## 🔄 Ansibleとchezmoiの役割分担

このプロジェクトは、**Ansible**と**chezmoi**を組み合わせたハイブリッドアプローチを採用しています。

### Ansible: システム基盤の構築

**対象**: システムレベルの設定とパッケージ管理

- パッケージのインストール（Linuxbrew、bat、delta、eza、gh、chezmoi等）
- システム設定（sudo、SSH、Docker）
- 環境固有の設定（WSL、Azure VM、EC2等）

**実行方法**:
```bash
cd ansible
ansible-playbook -i inventories/wsl/hosts site.yml
```

### chezmoi: 個人設定ファイルの管理

**対象**: ユーザー個別のドットファイル

- シェル設定（~/.bashrc、~/.zshrc）
- Git設定（~/.gitconfig）
- ターミナル設定（~/.tmux.conf、~/.config/starship.toml）
- PowerLine設定（~/.config/powerline/）

**実行方法**:
```bash
# 初回セットアップ
chezmoi init /path/to/devenv-bootstrap/dotfiles
# または GitHubから
chezmoi init https://github.com/your-username/dotfiles.git

# 変更を確認
chezmoi diff

# 適用
chezmoi apply -v
```

### 切り替え方法

`ansible/group_vars/all.yml` で管理方法を切り替え可能：

```yaml
# chezmoi で dotfiles を管理する場合は true に設定
# true の場合、Ansible は設定ファイルを配置しません
use_chezmoi_for_dotfiles: false  # デフォルト: Ansibleで管理
```

**推奨設定**: `use_chezmoi_for_dotfiles: true`

これにより、Ansibleはパッケージインストールのみを行い、設定ファイルはchezmoiで管理されます。

## 📖 使用方法

### 🔐 Zscaler証明書のセットアップ

Zscaler環境で作業する場合、ルート証明書を配置することで自動的にシステム証明書ストアに登録できます。

#### 証明書の配置

```bash
# 証明書を配置するディレクトリを作成
mkdir -p ~/.certs

# 証明書ファイルをコピー（以下のいずれかの形式に対応）
# 1. テキスト情報 + PEMブロック（openssl x509 -text 出力など）
# 2. 純粋なPEM形式（-----BEGIN CERTIFICATE-----から始まる）
# 3. DERバイナリ形式
cp /path/to/ZscalerRootCA.cer ~/.certs/
```

#### 自動処理の内容

`bootstrap.sh` を実行すると、以下の処理が自動的に行われます：

1. **証明書の検出**: `~/.certs/ZscalerRootCA.cer` の存在を確認
2. **形式の判定と変換**:
   - テキスト情報 + PEM: PEMブロックのみを抽出
   - 純粋なPEM: そのまま使用（べき等性）
   - DER形式: `openssl` で PEM 形式に変換
3. **システム証明書ストアへの追加**:
   - Ubuntu/Debian: `/usr/local/share/ca-certificates/` に配置し `update-ca-certificates` 実行
   - RHEL/Fedora: `/etc/pki/ca-trust/source/anchors/` に配置し `update-ca-trust` 実行
   - Arch Linux: `/etc/ca-certificates/trust-source/anchors/` に配置し `trust extract-compat` 実行
4. **登録の自動検証**: 証明書ストアへの追加後、自動的に検証スクリプトが実行されます
   - システム証明書ストアへの登録を確認
   - 証明書バンドルへの組み込みを確認
   - 証明書の有効性を検証
   - 検証結果をログに表示
5. **pip での証明書適用**: Ansible インストール時に証明書を自動適用

**注意**: 検証が失敗しても bootstrap.sh 全体は失敗しません（警告のみ）。手動で確認する場合は `./scripts/verify-zscaler-cert.sh --verbose` を実行してください。

#### 証明書の検証

bootstrap.sh 実行後、証明書が正しく登録されているかを手動で確認することもできます：

```bash
# 証明書の登録状況を確認
./scripts/verify-zscaler-cert.sh

# 詳細な情報を表示
./scripts/verify-zscaler-cert.sh --verbose
```

**検証内容**:
- ソース証明書ファイルの存在確認 (`~/.certs/ZscalerRootCA.{cer,pem}`)
- システム証明書ストアへの登録確認
- 証明書バンドルへの組み込み確認
- 証明書の有効性検証（`openssl` による）

**終了コード**:
- `0`: 証明書は正しく登録されています
- `1`: 証明書が未登録、または問題があります
- `2`: 証明書が無効です
- `3`: サポート外のプラットフォーム

### 基本的な使用方法

```bash
# デフォルト設定でインストール
./bootstrap.sh

# 実行前にプレビュー（Dry-run）
./bootstrap.sh --dry-run

# 詳細ログを表示
./bootstrap.sh --verbose

# カスタム仮想環境パスを指定
./bootstrap.sh --venv-path ~/custom-venv

# ヘルプを表示
./bootstrap.sh --help
```

### オプション

| オプション | 短縮形 | 説明 |
|-----------|--------|------|
| `--dry-run` | `-d` | 実際の変更を行わずに、実行内容をプレビュー |
| `--verbose` | `-v` | 詳細なデバッグログを表示 |
| `--venv-path PATH` | `-p PATH` | 仮想環境のカスタムパスを指定（デフォルト: リポジトリ直下の `.ansible-venv`） |
| `--help` | `-h` | ヘルプメッセージを表示 |

## 📋 前提条件

- **Python**: バージョン 3.8 以上
- **pip**: Python パッケージマネージャー
- **venv**: Python 仮想環境モジュール
- **openssl**: 証明書変換に必要（Zscaler環境の場合）
- **非rootユーザー**: セキュリティのため、rootでの実行は禁止されています

### ディストリビューション別の依存関係インストール

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv openssl build-essential libssl-dev libffi-dev
```

#### RHEL/CentOS/Fedora
```bash
sudo dnf install -y python3 python3-pip python3-virtualenv openssl gcc openssl-devel libffi-devel
```

#### Arch Linux
```bash
sudo pacman -Sy python python-pip openssl base-devel libffi
```

## 🎯 インストール後の使用方法

### 方法1: 仮想環境を有効化

```bash
source .ansible-venv/bin/activate
ansible --version
ansible-playbook playbook.yml
deactivate  # 終了時
```

### 方法2: 直接実行（有効化不要）

```bash
.ansible-venv/bin/ansible --version
.ansible-venv/bin/ansible-playbook playbook.yml
```

### 方法3: PATHに追加（オプション）

```bash
echo 'export PATH="$PWD/.ansible-venv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
ansible --version  # どこからでも実行可能
```

## 🔧 Ansible Playbook の実行

Ansibleのインストール後、開発環境のセットアップを自動化できます。環境に応じたインベントリファイルを指定して実行します。

### 基本的な実行方法

```bash
# 仮想環境を有効化
source .ansible-venv/bin/activate

# ansibleディレクトリに移動
cd ansible

# WSL環境でセットアップ実行
ansible-playbook -i inventories/wsl/hosts site.yml

# Azure VM環境でセットアップ実行
ansible-playbook -i inventories/azure-vm/hosts site.yml

# EC2環境でセットアップ実行
ansible-playbook -i inventories/ec2/hosts site.yml
```

### 対応環境

- **WSL**: Windows Subsystem for Linux (1/2)
- **Azure VM**: Azure Virtual Machines
- **EC2**: AWS EC2インスタンス
- **Hyper-V**: Hyper-V仮想マシン
- **ベアメタル**: 物理サーバー
- **Docker**: Dockerコンテナ

### 高度な使用方法

```bash
# Dry-run（変更を確認のみ）
ansible-playbook -i inventories/wsl/hosts site.yml --check

# 詳細ログ
ansible-playbook -i inventories/wsl/hosts site.yml -v

# 特定のタグのみ実行
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml --tags sudo

# ブートストラップのみ実行
ansible-playbook -i inventories/wsl/hosts playbooks/bootstrap.yml

# コンテナ環境専用セットアップ
ansible-playbook -i inventories/docker/hosts playbooks/containers.yml
```

詳細は [ansible/README.md](ansible/README.md) を参照してください。

## 🔍 トラブルシューティング

### Zscaler証明書関連の問題

#### 証明書の変換に失敗する

```bash
# エラー: "証明書の変換に失敗しました"
# 原因: 証明書ファイルの形式が不明、または破損している

# 確認方法:
# 1. ファイルの内容を確認
cat ~/.certs/ZscalerRootCA.cer

# 2. PEMブロックが含まれているか確認
grep "BEGIN CERTIFICATE" ~/.certs/ZscalerRootCA.cer

# 3. openssl で確認
openssl x509 -in ~/.certs/ZscalerRootCA.cer -text -noout

# DER形式の場合:
openssl x509 -inform DER -in ~/.certs/ZscalerRootCA.cer -text -noout

# 解決方法:
# - 正しい証明書ファイルを再取得
# - PEM形式で保存されていることを確認
```

#### 証明書が登録されているか確認したい

```bash
# 検証スクリプトを実行
./scripts/verify-zscaler-cert.sh --verbose

# 手動での確認方法:
# Ubuntu/Debian:
grep "Zscaler" /etc/ssl/certs/ca-certificates.crt

# RHEL/Fedora:
grep "Zscaler" /etc/pki/tls/certs/ca-bundle.crt

# Arch Linux:
grep "Zscaler" /etc/ssl/certs/ca-certificates.crt
```

#### SSL証明書検証エラー

```bash
# エラー: "SSL: CERTIFICATE_VERIFY_FAILED"
# 原因: Zscaler証明書がシステム証明書ストアに登録されていない

# 解決手順:
# 1. 証明書を配置
mkdir -p ~/.certs
cp /path/to/ZscalerRootCA.cer ~/.certs/

# 2. bootstrap.sh を再実行
./bootstrap.sh

# 3. 登録を確認
./scripts/verify-zscaler-cert.sh
```

#### opensslコマンドが見つからない

```bash
# エラー: "opensslコマンドが見つかりません"
# 原因: openssl パッケージがインストールされていない

# Ubuntu/Debian:
sudo apt update && sudo apt install -y openssl

# RHEL/Fedora:
sudo dnf install -y openssl

# Arch Linux:
sudo pacman -Sy openssl
```

### Python バージョンが古い

```bash
# Pythonのバージョンを確認
python3 --version

# Python 3.8以上が必要です
# 必要に応じてPythonをアップグレード
```

### rootユーザーエラー

```bash
# エラー: "This script should NOT be run as root"
# 解決方法: sudoを使わずに実行
./bootstrap.sh  # sudo なし
```

### すでにインストール済み

スクリプトは既存のインストールを検出し、再インストールをスキップします。再インストールが必要な場合：

```bash
# 仮想環境を削除
rm -rf .ansible-venv

# スクリプトを再実行
./bootstrap.sh
```

### 依存関係が見つからない

```bash
# エラーメッセージに従って依存関係をインストール
# スクリプトが具体的なコマンドを提示します
```

## 🔒 セキュリティ

- **非root実行**: スクリプトはroot権限を要求せず、通常ユーザーで実行します
- **仮想環境の分離**: システムPythonを変更せず、独立した環境を作成
- **厳格モード**: `set -Eeuo pipefail` によるエラーの早期検出
- **クリーンアップ**: エラー時でも一時ファイルを自動削除

## 📊 終了コード

| コード | 意味 |
|--------|------|
| 0 | 成功 |
| 1 | 一般的なエラー |
| 2 | 不正な引数 |
| 3 | サポート外のプラットフォーム |
| 4 | 依存関係の不足 |
| 5 | Pythonバージョンが古い |
| 6 | rootユーザーで実行（禁止） |

## 🛠 開発とテスト

### Dry-runモードでテスト

```bash
# 変更を加えずに実行内容を確認
./bootstrap.sh --dry-run --verbose
```

### ShellCheckによる静的解析

```bash
# ShellCheckがインストールされている場合
shellcheck bootstrap.sh
```

### 複数ディストリビューションでのテスト

```bash
# Docker環境でテスト
docker run -it --rm -v "$PWD:/work" ubuntu:22.04 /work/bootstrap.sh
docker run -it --rm -v "$PWD:/work" fedora:latest /work/bootstrap.sh
docker run -it --rm -v "$PWD:/work" archlinux:latest /work/bootstrap.sh
```

## 📝 ライセンス

このスクリプトは、プロジェクトのライセンスに従います。

## 🤝 貢献

改善の提案やバグ報告は、Issueまたはプルリクエストでお願いします。

## 📚 参考資料

- [Ansible Documentation](https://docs.ansible.com/)
- [Python Virtual Environments](https://docs.python.org/3/library/venv.html)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)
