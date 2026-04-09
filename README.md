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

## 🚀 クイックスタート

```bash
# リポジトリをクローン
git clone <repository-url>
cd dev-env-bootstrap

# スクリプトを実行
./bootstrap.sh
```

## 📖 使用方法

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
| `--venv-path PATH` | `-p PATH` | 仮想環境のカスタムパスを指定（デフォルト: `~/.ansible-venv`） |
| `--help` | `-h` | ヘルプメッセージを表示 |

## 📋 前提条件

- **Python**: バージョン 3.8 以上
- **pip**: Python パッケージマネージャー
- **venv**: Python 仮想環境モジュール
- **非rootユーザー**: セキュリティのため、rootでの実行は禁止されています

### ディストリビューション別の依存関係インストール

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv build-essential libssl-dev libffi-dev
```

#### RHEL/CentOS/Fedora
```bash
sudo dnf install -y python3 python3-pip python3-virtualenv gcc openssl-devel libffi-devel
```

#### Arch Linux
```bash
sudo pacman -Sy python python-pip base-devel openssl libffi
```

## 🎯 インストール後の使用方法

### 方法1: 仮想環境を有効化

```bash
source ~/.ansible-venv/bin/activate
ansible --version
ansible-playbook playbook.yml
deactivate  # 終了時
```

### 方法2: 直接実行（有効化不要）

```bash
~/.ansible-venv/bin/ansible --version
~/.ansible-venv/bin/ansible-playbook playbook.yml
```

### 方法3: PATHに追加（オプション）

```bash
echo 'export PATH="$HOME/.ansible-venv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
ansible --version  # どこからでも実行可能
```

## 🔧 Ansible Playbook の実行

Ansibleのインストール後、開発環境のセットアップを自動化できます。環境に応じたインベントリファイルを指定して実行します。

### 基本的な実行方法

```bash
# 仮想環境を有効化
source ~/.ansible-venv/bin/activate

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
rm -rf ~/.ansible-venv

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
