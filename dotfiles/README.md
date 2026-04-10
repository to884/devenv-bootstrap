# Dotfiles - chezmoi で管理する個人設定

このディレクトリには、chezmoiで管理される個人設定ファイル（dotfiles）が含まれています。

## 📋 概要

このdotfilesリポジトリは、開発環境の個人設定を複数のマシン間で同期・管理するためのものです。  
[chezmoi](https://www.chezmoi.io/)を使用して、設定ファイルのバージョン管理とデプロイを行います。

## ✨ 管理される設定ファイル

### シェル設定
- `~/.bashrc` - Bash設定（Linuxbrew、starshipの初期化）
- `~/.zshrc` - Zsh設定（Linuxbrew、starshipの初期化）

### Git設定
- `~/.gitconfig` - Git全体設定（delta、エイリアス、ユーザー情報）

### SSH設定
- `~/.ssh/config` - SSH クライアント設定（接続設定、ホスト別設定、セキュリティ設定）

### ターミナルツール設定
- `~/.tmux.conf` - tmux設定（キーバインド、プラグイン）
- `~/.config/powerline/` - PowerLine設定（ステータスバー）
- `~/.config/starship.toml` - starshipプロンプト設定

## 🚀 セットアップ

### 前提条件

1. **Ansibleでシステム基盤を構築**（chezmoi含む）
   ```bash
   cd ansible
   ansible-playbook -i inventories/wsl/hosts site.yml
   ```

2. **chezmoiが利用可能であること**
   ```bash
   which chezmoi
   # /home/linuxbrew/.linuxbrew/bin/chezmoi
   ```

### 初回セットアップ

#### 1. このリポジトリからdotfilesを初期化

```bash
# このdotfilesディレクトリを使用する場合
chezmoi init /path/to/devenv-bootstrap/dotfiles

# GitHubリポジトリから初期化する場合
chezmoi init https://github.com/your-username/dotfiles.git
```

#### 2. 変更内容を確認

```bash
# dry-runモードで確認
chezmoi diff
```

#### 3. 設定を適用

```bash
# 設定ファイルを適用
chezmoi apply -v
```

### 日常的な使い方

#### 設定ファイルを編集

```bash
# chezmoiエディタで編集
chezmoi edit ~/.bashrc

# または直接編集
chezmoi edit --apply ~/.gitconfig
```

#### 変更を確認して適用

```bash
# 変更内容を確認
chezmoi diff

# 変更を適用
chezmoi apply -v
```

#### 新しいマシンで設定を同期

```bash
# GitHubリポジトリから初期化
chezmoi init https://github.com/your-username/dotfiles.git

# 適用
chezmoi apply
```

## 📁 ディレクトリ構造

```
dotfiles/
├── README.md                    # このファイル
├── .chezmoi.toml.tmpl          # chezmoi設定（テンプレート）
├── dot_bashrc.tmpl             # ~/.bashrc
├── dot_zshrc.tmpl              # ~/.zshrc
├── dot_gitconfig.tmpl          # ~/.gitconfig
├── dot_tmux.conf               # ~/.tmux.conf
└── dot_config/
    ├── starship.toml           # ~/.config/starship.toml
    └── powerline/              # ~/.config/powerline/
        ├── config.json
        ├── colors.json
        ├── colorschemes/
        │   └── tmux/
        │       └── tmux-colorscheme.json
        └── themes/
            └── tmux/
                └── tmux-theme.json
```

## 🔄 Ansibleとの関係

### 役割分担

| 管理対象 | ツール | 理由 |
|---------|--------|------|
| システムパッケージ | Ansible | べき等性、root権限が必要 |
| Linuxbrewパッケージ | Ansible | 環境構築の一部 |
| 個人設定ファイル | chezmoi | ユーザー設定、頻繁な変更 |
| システム設定 | Ansible | sudoers、SSH、Docker等 |

### ワークフロー

```bash
# 1. システム基盤をAnsibleで構築
ansible-playbook -i inventories/wsl/hosts site.yml

# 2. 個人設定をchezmoiで適用
chezmoi init https://github.com/your-username/dotfiles.git
chezmoi apply
```

## 📖 参考リンク

- [chezmoi公式ドキュメント](https://www.chezmoi.io/)
- [chezmoi Quick Start](https://www.chezmoi.io/quick-start/)
- [chezmoi User Guide](https://www.chezmoi.io/user-guide/setup/)

## 🔧 カスタマイズ

### ユーザー情報の設定

`.chezmoi.toml.tmpl` でユーザー固有の情報を管理できます：

```toml
[data]
    name = "Your Name"
    email = "your.email@example.com"
    github_user = "your-github-username"
```

これらの変数は `.tmpl` ファイル内で使用できます：

```bash
# dot_gitconfig.tmpl
[user]
    name = {{ .name }}
    email = {{ .email }}
```

## 🔒 セキュリティ

- 機密情報（APIキー、パスワード）は**絶対に**コミットしないでください
- 必要な場合は `.chezmoiignore` で除外するか、暗号化機能を使用してください
- `.gitconfig` のユーザー情報はテンプレート変数を使用してください
