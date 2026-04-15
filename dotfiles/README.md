# Dotfiles - chezmoi で管理する個人設定

このディレクトリには、chezmoiで管理される個人設定ファイル（dotfiles）が含まれています。

## 📋 概要

このdotfilesリポジトリは、開発環境の個人設定を複数のマシン間で同期・管理するためのものです。  
[chezmoi](https://www.chezmoi.io/)を使用して、設定ファイルのバージョン管理とデプロイを行います。

## ✨ 管理される設定ファイル

### シェル設定
- `~/.bashrc` - Bash設定（Linuxbrew、starshipの初期化）
- `~/.bash_profile` - Bashログインシェル設定（Linuxbrew shellenv）
- `~/.profile` - POSIX互換ログインシェル設定
- `~/.zshrc` - Zsh設定（Linuxbrew、starshipの初期化）

**シェル設定ファイルの役割**:
- `.bashrc` - インタラクティブシェル（ターミナル起動時）で読み込まれる
- `.bash_profile` - ログインシェル（SSH、ttyログイン等）で読み込まれる。`.bashrc`を読み込む役割も持つ
- `.profile` - POSIX互換シェル（sh、dashなど）のログインシェルで読み込まれる。bashは`.bash_profile`が存在する場合、このファイルを読み込まない

すべてのシェル設定ファイルに Linuxbrew の shellenv が設定されており、PATH や環境変数が正しく設定されます。

### Git設定
- `~/.gitconfig` - Git全体設定（delta、エイリアス、ユーザー情報）

### curl設定
- `~/.curlrc` - curl全体設定（Zscaler証明書パス）

### SSH設定
- `~/.ssh/config` - SSH クライアント設定（接続設定、ホスト別設定、セキュリティ設定）

### ターミナルツール設定
- `~/.tmux.conf` - tmux設定（キーバインド、プラグイン）
- `~/.config/powerline/` - PowerLine設定（ステータスバー）
- `~/.config/starship.toml` - starshipプロンプト設定
- `~/.config/topgrade.toml` - topgrade設定（パッケージ一括更新）

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

3. **Nerd Fontのインストールと設定**
   - Starship、Powerline、Tmuxなどのツールが、プロンプトやステータスバーでアイコンを正しく表示するために必要です
   - 推奨フォント:
     - [Hack Nerd Font](https://www.nerdfonts.com/)
     - [JetBrains Mono Nerd Font](https://www.nerdfonts.com/)
     - [Fira Code Nerd Font](https://www.nerdfonts.com/)
   - インストール方法: [Nerd Fonts公式サイト](https://www.nerdfonts.com/) を参照
   - インストール後、ターミナルエミュレータの設定でNerd Fontを選択してください
   - ⚠️ アイコンが正しく表示されない場合は、フォント設定を確認してください

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
├── dot_curlrc.tmpl             # ~/.curlrc（Zscaler証明書設定）
├── dot_tmux.conf               # ~/.tmux.conf
├── dot_ssh/
│   └── config.tmpl             # ~/.ssh/config
└── dot_config/
    ├── starship.toml           # ~/.config/starship.toml
    ├── topgrade.toml           # ~/.config/topgrade.toml
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

### 主要な設定ファイルの説明

#### topgrade 設定 (`~/.config/topgrade.toml`)

topgrade は様々なパッケージマネージャーを一括で更新するツールです。

```bash
# すべてのパッケージを更新
topgrade

# dry-run モード（実際には更新しない）
topgrade --dry-run

# 特定のステップのみ実行
topgrade --only brew

# 特定のステップをスキップ
topgrade --disable system
```

設定ファイルで無効化・カスタマイズ可能：
- Homebrew の自動クリーンアップ
- システムパッケージの更新（WSL環境では無効化推奨）
- Git リポジトリの一括 pull
- カスタムコマンドの実行

参考: [topgrade GitHub](https://github.com/topgrade-rs/topgrade)

#### SSH 設定 (`~/.ssh/config`)

SSH 接続設定を一元管理：
- グローバル設定（接続維持、圧縮、タイムアウト）
- ホスト別の設定（GitHub、開発サーバー、ジャンプホスト）
- WSL 環境での特殊設定（Windows の SSH エージェント利用）

設定例を参考にカスタマイズしてください。

## 🔒 セキュリティ

- 機密情報（APIキー、パスワード）は**絶対に**コミットしないでください
- 必要な場合は `.chezmoiignore` で除外するか、暗号化機能を使用してください
- `.gitconfig` のユーザー情報はテンプレート変数を使用してください

## 🔐 Zscaler環境での使用

Zscaler等のSSLインスペクションを使用する企業環境では、curl等のHTTPSツールが証明書エラーで失敗することがあります。  
このdotfilesリポジトリには、Zscaler証明書を自動的に設定する `.curlrc` が含まれています。

### セットアップ手順

1. **Zscaler証明書ファイルを配置**
   ```bash
   mkdir -p ~/.certs
   # Windows環境から証明書をコピー（例）
   cp /mnt/c/Users/YourName/Documents/ZscalerRootCA.cer ~/.certs/
   ```

2. **bootstrap.sh を実行して証明書を変換・登録**
   ```bash
   cd /path/to/devenv-bootstrap
   ./bootstrap.sh
   ```
   
   このスクリプトが以下を実行します：
   - `.cer` 形式を `.pem` 形式に変換
   - システム証明書ストアに登録
   - `~/.certs/ZscalerRootCA.pem` を作成

3. **dotfilesを適用（chezmoiで自動）**
   ```bash
   chezmoi apply
   ```
   
   これにより `~/.curlrc` が作成され、以下の設定が適用されます：
   ```
   cacert = ~/.certs/ZscalerRootCA.pem
   ```

### 動作確認

```bash
# curl でHTTPSサイトにアクセス
curl -I https://github.com

# 証明書検証が正常に動作すれば成功
# HTTP/2 200 のレスポンスが返ります
```

### トラブルシューティング

証明書エラーが発生する場合：

```bash
# 証明書の確認
ls -la ~/.certs/ZscalerRootCA.pem

# .curlrc の確認
cat ~/.curlrc

# システム証明書ストアの確認
./scripts/verify-zscaler-cert.sh --verbose
```

参考: [Zscaler証明書検証スクリプト](../scripts/verify-zscaler-cert.sh)
