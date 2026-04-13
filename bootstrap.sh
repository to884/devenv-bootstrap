#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================================
# Ansible ブートストラップスクリプト
# ============================================================================
#
# 目的:
#   リポジトリの初期セットアップ用のクロスディストリビューション対応Ansibleインストールスクリプト。
#   システムPythonを汚染しないよう、Python仮想環境にAnsibleをインストールします。
#
# 対応ディストリビューション:
#   - Ubuntu/Debian (apt)
#   - RHEL/CentOS/Fedora (dnf/yum)
#   - Arch Linux (pacman)
#
# 対応実行環境:
#   - WSL (Windows Subsystem for Linux) 1/2
#   - Hyper-V 仮想マシン
#   - Azure VM (Linux Virtual Machines)
#   - AWS EC2 (Linux instances)
#   - Docker コンテナ
#   - ベアメタル Linux サーバー
#
# 使用方法:
#   ./bootstrap.sh [オプション]
#
# オプション:
#   -d, --dry-run         実際の変更を行わず、実行内容を表示
#   -v, --verbose         詳細/デバッグログを有効化
#   -p, --venv-path PATH  仮想環境のカスタムパスを指定
#                         (デフォルト: $HOME/.ansible-venv)
#   -h, --help            このヘルプメッセージを表示
#
# 必要要件:
#   - Python 3.8 以上
#   - pip (python3-pip)
#   - venv モジュール (一部のディストリビューションでは python3-venv)
#   - 非rootユーザー (スクリプトはrootでの実行を拒否します)
#
# 終了コード:
#   0 - 成功
#   1 - 一般的なエラー
#   2 - 不正な引数
#   3 - サポート外のプラットフォーム
#   4 - 依存関係の不足
#   5 - Pythonバージョンが古い
#   6 - rootユーザーで実行 (禁止)
#
# 使用例:
#   ./bootstrap.sh                    # デフォルト設定でインストール
#   ./bootstrap.sh --dry-run          # 実行内容をプレビュー
#   ./bootstrap.sh --verbose          # 詳細ログを表示
#   ./bootstrap.sh --venv-path ~/venv # カスタムvenvパスを指定
#
# ============================================================================

# ============================================================================
# グローバル変数とデフォルト値

# スクリプトの場所を取得
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Zscalerルート証明書のパス
CERT_FILE="${HOME}/.certs/ZscalerRootCA.cer"

# =========================================================================
# Zscalerルート証明書の自動インポート
# =========================================================================

update_zscaler_root_certificates() {
    log_info "Zscalerルート証明書の更新を確認中..."

    # 証明書ファイルの存在チェック
    if [[ ! -f "$CERT_FILE" ]]; then
        log_info "Zscalerルート証明書が見つかりません: $CERT_FILE"
        log_info "証明書が必要な場合は、$CERT_FILE に配置してください"
        return 0
    fi

    log_info "Zscalerルート証明書ファイル: $CERT_FILE"

    # ディストリ検出
    local distro pkg_mgr
    distro=$(detect_linux_distro)
    pkg_mgr=$(detect_package_manager "$distro")

    local updated=0
    case "$pkg_mgr" in
        apt)
            # Debian/Ubuntu 系
            local dest="/usr/local/share/ca-certificates/$(basename "$CERT_FILE")"
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "[dry-run] cp \"$CERT_FILE\" \"$dest\""
                echo "[dry-run] update-ca-certificates"
            else
                if [[ ! -f "$dest" ]] || ! cmp -s "$CERT_FILE" "$dest"; then
                    log_info "証明書をコピー: $CERT_FILE → $dest"
                    sudo cp "$CERT_FILE" "$dest"
                    sudo chmod 644 "$dest"
                    sudo update-ca-certificates
                    log_success "証明書ストアを更新しました (Debian/Ubuntu系)"
                    updated=1
                else
                    log_info "証明書は既に最新です: $dest"
                fi
            fi
            ;;
        dnf|yum)
            # RHEL/CentOS/Fedora 系
            local dest="/etc/pki/ca-trust/source/anchors/$(basename "$CERT_FILE")"
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "[dry-run] cp \"$CERT_FILE\" \"$dest\""
                echo "[dry-run] update-ca-trust extract"
            else
                if [[ ! -f "$dest" ]] || ! cmp -s "$CERT_FILE" "$dest"; then
                    log_info "証明書をコピー: $CERT_FILE → $dest"
                    sudo cp "$CERT_FILE" "$dest"
                    sudo chmod 644 "$dest"
                    sudo update-ca-trust extract
                    log_success "証明書ストアを更新しました (RHEL/Fedora系)"
                    updated=1
                else
                    log_info "証明書は既に最新です: $dest"
                fi
            fi
            ;;
        pacman)
            # Arch Linux 系
            local dest="/etc/ca-certificates/trust-source/anchors/$(basename "$CERT_FILE")"
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "[dry-run] cp \"$CERT_FILE\" \"$dest\""
                echo "[dry-run] trust extract-compat"
            else
                if [[ ! -f "$dest" ]] || ! cmp -s "$CERT_FILE" "$dest"; then
                    log_info "証明書をコピー: $CERT_FILE → $dest"
                    sudo cp "$CERT_FILE" "$dest"
                    sudo chmod 644 "$dest"
                    sudo trust extract-compat
                    log_success "証明書ストアを更新しました (Arch系)"
                    updated=1
                else
                    log_info "証明書は既に最新です: $dest"
                fi
            fi
            ;;
        *)
            log_warning "証明書ストアの自動更新は未対応のディストリビューションです: $distro"
            ;;
    esac

    # 証明書ストア更新後に openssl s_client で接続テスト
    if [[ "$updated" == "1" ]]; then
        local test_host="www.google.com"
        local test_port=443
        log_info "証明書インストール後の接続テスト: openssl s_client -connect ${test_host}:${test_port}"
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] openssl s_client -connect ${test_host}:${test_port} -CApath /etc/ssl/certs"
        else
            if ! openssl s_client -connect "${test_host}:${test_port}" -CApath /etc/ssl/certs < /dev/null | grep -q 'Verify return code: 0 (ok)'; then
                log_error "openssl s_client による接続テストに失敗しました (証明書ストアの反映を確認してください)"
                exit 1
            else
                log_success "openssl s_client による接続テスト成功 (証明書ストアが有効です)"
            fi
        fi
    fi

    return 0
}
# ============================================================================

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly TIMESTAMP="$(date +'%Y-%m-%d %H:%M:%S')"

# 設定
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
VENV_PATH="${VENV_PATH:-${HOME}/.ansible-venv}"
MIN_PYTHON_VERSION="3.8"
ANSIBLE_PACKAGE="ansible"

# 一時ディレクトリ (終了時にクリーンアップ)
TMPDIR=""

# カラーコード (ターミナルでない場合は無効化)
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_GRAY='\033[0;90m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_GRAY=''
fi

# ============================================================================
# クリーンアップとエラーハンドリング用のトラップハンドラー
# ============================================================================

cleanup() {
    local exit_code=$?

    # 一時ディレクトリが存在する場合はクリーンアップ
    if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
        log_debug "一時ディレクトリをクリーンアップ中: $TMPDIR"
        rm -rf "$TMPDIR"
    fi

    if [[ $exit_code -ne 0 ]]; then
        log_error "スクリプトが終了コード $exit_code で失敗しました"
    fi
}

error_handler() {
    local line_number=$1
    log_error "$line_number 行目でエラーが発生しました"
}

trap cleanup EXIT
trap 'error_handler $LINENO' ERR

# ============================================================================
# ログ関数
# ============================================================================

log_info() {
    echo -e "${COLOR_BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${COLOR_RESET} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${COLOR_RESET} $*" >&2
}

log_warning() {
    echo -e "${COLOR_YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${COLOR_RESET} $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${COLOR_GRAY}[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG:${COLOR_RESET} $*" >&2
    fi
}

# ============================================================================
# 使用方法とヘルプ
# ============================================================================

usage() {
    local exit_code="${1:-0}"

    cat >&2 <<EOF
使用方法: $SCRIPT_NAME [オプション]

リポジトリの初期セットアップ用のクロスディストリビューション対応Ansibleインストールスクリプト。

オプション:
  -d, --dry-run         実際の変更を行わず、実行内容を表示
  -v, --verbose         詳細/デバッグログを有効化
  -p, --venv-path PATH  仮想環境のカスタムパスを指定
                        (デフォルト: \$HOME/.ansible-venv)
  -h, --help            このヘルプメッセージを表示

使用例:
  $SCRIPT_NAME                    # デフォルト設定でインストール
  $SCRIPT_NAME --dry-run          # 実行内容をプレビュー
  $SCRIPT_NAME --verbose          # 詳細ログを表示
  $SCRIPT_NAME --venv-path ~/venv # カスタムvenvパスを指定

対応ディストリビューション:
  - Ubuntu/Debian (apt)
  - RHEL/CentOS/Fedora (dnf/yum)
  - Arch Linux (pacman)

対応実行環境:
  - WSL 1/2, Hyper-V, Azure VM, AWS EC2, Docker, ベアメタル

必要要件:
  - Python 3.8 以上
  - pip (python3-pip)
  - venv モジュール
  - 非rootユーザー

終了コード:
  0 - 成功
  1 - 一般的なエラー
  2 - 不正な引数
  3 - サポート外のプラットフォーム
  4 - 依存関係の不足
  5 - Pythonバージョンが古い
  6 - rootユーザーで実行 (禁止)

EOF
    exit "$exit_code"
}

# ============================================================================
# プラットフォーム検出
# ============================================================================

detect_linux_distro() {
    # /etc/os-releaseを使用してLinuxディストリビューションを検出
    # 戻り値: 小文字のディストリビューションID (例: "ubuntu", "fedora", "arch")

    log_debug "Linuxディストリビューションを検出中..."

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/lsb-release ]]; then
        # shellcheck source=/dev/null
        source /etc/lsb-release
        echo "${DISTRIB_ID:-unknown}" | tr '[:upper:]' '[:lower:]'
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    # 利用可能なパッケージマネージャーを検出
    # 戻り値: パッケージマネージャーコマンド (apt, dnf, yum, pacman, または unknown)

    log_debug "パッケージマネージャーを検出中..."

    local distro="$1"
    local pkg_mgr=""

    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            if command -v apt >/dev/null 2>&1; then
                pkg_mgr="apt"
            fi
            ;;
        fedora|rhel|centos|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                pkg_mgr="dnf"
            elif command -v yum >/dev/null 2>&1; then
                pkg_mgr="yum"
            fi
            ;;
        arch|manjaro|endeavouros)
            if command -v pacman >/dev/null 2>&1; then
                pkg_mgr="pacman"
            fi
            ;;
        *)
            pkg_mgr="unknown"
            ;;
    esac

    echo "$pkg_mgr"
}

# ============================================================================
# 依存関係チェック
# ============================================================================

check_not_root() {
    # スクリプトがrootで実行されていないことを確認 (セキュリティベストプラクティス)

    if [[ $EUID -eq 0 ]]; then
        log_error "このスクリプトはrootで実行すべきではありません"
        log_error "仮想環境のインストールには通常ユーザーが必要です"
        log_error "sudoを使わず、または非rootユーザーで実行してください"
        exit 6
    fi
}

check_python_version() {
    # Python 3.xが利用可能で、最小バージョン要件を満たしているかチェック

    log_debug "Pythonバージョンを確認中..."

    if ! command -v python3 >/dev/null 2>&1; then
        log_error "python3が見つかりません。Python 3.$MIN_PYTHON_VERSION 以上をインストールしてください"
        return 1
    fi

    local python_version
    python_version=$(python3 -c 'import sys; print("." .join(map(str, sys.version_info[:2])))')

    log_debug "検出されたPythonバージョン: $python_version"

    # バージョン比較: 簡易比較用に整数に変換
    local version_major version_minor min_major min_minor
    version_major=$(echo "$python_version" | cut -d. -f1)
    version_minor=$(echo "$python_version" | cut -d. -f2)
    min_major=$(echo "$MIN_PYTHON_VERSION" | cut -d. -f1)
    min_minor=$(echo "$MIN_PYTHON_VERSION" | cut -d. -f2)

    if [[ $version_major -lt $min_major ]] || \
       [[ $version_major -eq $min_major && $version_minor -lt $min_minor ]]; then
        log_error "Pythonバージョン $python_version は古すぎます"
        log_error "最小必要バージョン: $MIN_PYTHON_VERSION"
        exit 5
    fi

    log_debug "Pythonバージョンチェック合格: $python_version >= $MIN_PYTHON_VERSION"
    return 0
}

check_dependencies() {
    # 必要なシステム依存関係をチェック

    log_info "依存関係を確認中..."

    local -a missing_deps=()

    # Python 3をチェック
    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps+=("python3")
    fi

    # pipをチェック
    if ! command -v pip3 >/dev/null 2>&1 && ! python3 -m pip --version >/dev/null 2>&1; then
        missing_deps+=("pip3 (python3-pip)")
    fi

    # venvモジュールをチェック
    if ! python3 -m venv --help >/dev/null 2>&1; then
        missing_deps+=("python3-venv")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "必要な依存関係が不足しています: ${missing_deps[*]}"
        log_error "パッケージマネージャーを使用してインストールしてください"
        log_error ""

        local distro pkg_mgr
        distro=$(detect_linux_distro)
        pkg_mgr=$(detect_package_manager "$distro")

        case "$pkg_mgr" in
            apt)
                log_error "インストール方法: sudo apt update && sudo apt install -y python3 python3-pip python3-venv"
                ;;
            dnf)
                log_error "インストール方法: sudo dnf install -y python3 python3-pip python3-virtualenv"
                ;;
            yum)
                log_error "インストール方法: sudo yum install -y python3 python3-pip python3-virtualenv"
                ;;
            pacman)
                log_error "インストール方法: sudo pacman -Sy python python-pip"
                ;;
            *)
                log_error "以下をインストールしてください: python3, python3-pip, python3-venv"
                ;;
        esac

        exit 4
    fi

    log_success "すべての依存関係が見つかりました"
    return 0
}

# ============================================================================
# Ansible インストール関数
# ============================================================================

is_ansible_installed() {
    # Ansibleが既にインストールされているかチェック (venvまたはグローバル)
    # 戻り値: インストール済みなら0、未インストールなら1

    log_debug "既存のAnsibleインストールを確認中..."

    # 最初に仮想環境をチェック
    if [[ -f "${VENV_PATH}/bin/ansible" ]]; then
        local version
        version=$("${VENV_PATH}/bin/ansible" --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_info "Ansibleは既に仮想環境にインストール済みです: バージョン $version"
        return 0
    fi

    # グローバルにインストールされているかチェック
    if command -v ansible >/dev/null 2>&1; then
        local version
        version=$(ansible --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_warning "Ansibleがグローバルに見つかりました (バージョン $version) が、仮想環境には未インストールです"
        log_warning "仮想環境にインストールします: $VENV_PATH"
        return 1
    fi

    log_debug "Ansibleが見つかりません"
    return 1
}

install_system_packages() {
    # Ansible用のシステムレベル依存関係をインストール (必要な場合)
    # 一部のPythonパッケージのビルド依存関係が利用可能であることを保証

    local distro="$1"
    local pkg_mgr="$2"

    log_info "システム依存関係をインストール中..."

    local -a packages=()

    case "$pkg_mgr" in
        apt)
            packages=("python3" "python3-pip" "python3-venv" "build-essential" "libssl-dev" "libffi-dev")
            ;;
        dnf|yum)
            packages=("python3" "python3-pip" "python3-virtualenv" "gcc" "openssl-devel" "libffi-devel")
            ;;
        pacman)
            packages=("python" "python-pip" "base-devel" "openssl" "libffi")
            ;;
        *)
            log_warning "不明なパッケージマネージャー、システムパッケージのインストールをスキップします"
            return 0
            ;;
    esac

    log_debug "インストールするシステムパッケージ: ${packages[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] 次のパッケージをインストールします: ${packages[*]}"
        return 0
    fi

    # 注: これにはsudoが必要ですが、最初に既にインストール済みかチェックします
    local -a missing_packages=()

    case "$pkg_mgr" in
        apt)
            for pkg in "${packages[@]}"; do
                if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                    missing_packages+=("$pkg")
                fi
            done
            ;;
        dnf|yum)
            for pkg in "${packages[@]}"; do
                if ! rpm -q "$pkg" >/dev/null 2>&1; then
                    missing_packages+=("$pkg")
                fi
            done
            ;;
        pacman)
            for pkg in "${packages[@]}"; do
                if ! pacman -Q "$pkg" >/dev/null 2>&1; then
                    missing_packages+=("$pkg")
                fi
            done
            ;;
    esac

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "すべてのシステムパッケージが既にインストール済みです"
        return 0
    fi

    log_warning "一部のシステムパッケージが不足しています: ${missing_packages[*]}"
    log_warning "sudo権限で手動インストールが必要な場合があります:"

    case "$pkg_mgr" in
        apt)
            log_warning "  sudo apt update && sudo apt install -y ${missing_packages[*]}"
            ;;
        dnf)
            log_warning "  sudo dnf install -y ${missing_packages[*]}"
            ;;
        yum)
            log_warning "  sudo yum install -y ${missing_packages[*]}"
            ;;
        pacman)
            log_warning "  sudo pacman -Sy ${missing_packages[*]}"
            ;;
    esac

    log_warning "Ansibleのインストールを続行します..."
    return 0
}

install_via_pip() {
    # Python仮想環境にAnsibleをインストール

    log_info "仮想環境にAnsibleをインストール中: $VENV_PATH"

    # インストール用の一時ディレクトリを作成
    TMPDIR=$(mktemp -d) || {
        log_error "一時ディレクトリの作成に失敗しました"
        exit 1
    }

    # 仮想環境が存在しない場合は作成
    if [[ ! -d "$VENV_PATH" ]]; then
        log_info "Python仮想環境を作成中..."

        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[dry-run] 実行予定: python3 -m venv \"$VENV_PATH\""
        else
            python3 -m venv "$VENV_PATH" || {
                log_error "仮想環境の作成に失敗しました"
                exit 1
            }
            log_success "仮想環境を作成しました"
        fi
    else
        log_info "仮想環境は既に存在します: $VENV_PATH"
    fi

    # 仮想環境内のpipをアップグレード
    log_info "pipをアップグレード中..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] 実行予定: \"$VENV_PATH/bin/pip\" install --upgrade pip"
    else
        "$VENV_PATH/bin/pip" install --upgrade pip >/dev/null 2>&1 || {
            log_warning "pipのアップグレードに失敗しました (続行します)"
        }
    fi

    # Ansibleをインストール
    log_info "Ansibleパッケージをインストール中..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] 実行予定: \"$VENV_PATH/bin/pip\" install \"$ANSIBLE_PACKAGE\""
    else
        "$VENV_PATH/bin/pip" install "$ANSIBLE_PACKAGE" || {
            log_error "Ansibleのインストールに失敗しました"
            exit 1
        }

        # インストールを確認
        local version
        version=$("$VENV_PATH/bin/ansible" --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_success "Ansibleのインストールに成功しました: バージョン $version"
    fi

    return 0
}

# ============================================================================
# メインインストールフロー
# ============================================================================


main() {
    log_info "Ansibleブートストラップスクリプトを開始しました"
    log_debug "スクリプトディレクトリ: $SCRIPT_DIR"
    log_debug "Dry-runモード: $DRY_RUN"
    log_debug "Verboseモード: $VERBOSE"
    log_debug "仮想環境パス: $VENV_PATH"

    # Zscalerルート証明書の自動インポート
    update_zscaler_root_certificates

    # セキュリティチェック: rootでの実行を拒否
    check_not_root

    # プラットフォームを検出
    log_info "プラットフォームを検出中..."
    local distro pkg_mgr
    distro=$(detect_linux_distro)
    pkg_mgr=$(detect_package_manager "$distro")

    log_info "検出されたディストリビューション: $distro"
    log_info "パッケージマネージャー: $pkg_mgr"

    # プラットフォームサポートを検証
    if [[ "$pkg_mgr" == "unknown" ]]; then
        log_error "サポート外のLinuxディストリビューション: $distro"
        log_error "このスクリプトがサポートするのは: Ubuntu/Debian, RHEL/CentOS/Fedora, Arch Linux"
        exit 3
    fi

    # Pythonバージョンをチェック
    check_python_version

    # 依存関係をチェック
    check_dependencies

    # Ansibleが既にインストールされているかチェック
    if is_ansible_installed; then
        log_success "Ansibleは既に仮想環境にインストール済みです"
        log_info "仮想環境の場所: $VENV_PATH"
        log_info "Ansibleを使用するには、仮想環境を有効化してください:"
        log_info "  source $VENV_PATH/bin/activate"
        log_info "または直接実行:"
        log_info "  $VENV_PATH/bin/ansible --version"
        log_info ""
        log_info "再インストールするには、まず仮想環境を削除してください:"
        log_info "  rm -rf $VENV_PATH"
        exit 0
    fi

    # システム依存関係をインストール (必要な場合)
    install_system_packages "$distro" "$pkg_mgr"

    # 仮想環境にpip経由でAnsibleをインストール
    install_via_pip

    # 最終サマリー
    echo ""
    log_success "============================================"
    log_success "Ansibleのインストールが正常に完了しました！"
    log_success "============================================"
    echo ""
    log_info "仮想環境の場所: $VENV_PATH"
    echo ""
    log_info "Ansibleを使用するには、仮想環境を有効化してください:"
    log_info "  ${COLOR_GREEN}source $VENV_PATH/bin/activate${COLOR_RESET}"
    echo ""
    log_info "または、有効化せずにAnsibleを直接実行:"
    log_info "  ${COLOR_GREEN}$VENV_PATH/bin/ansible --version${COLOR_RESET}"
    log_info "  ${COLOR_GREEN}$VENV_PATH/bin/ansible-playbook playbook.yml${COLOR_RESET}"
    echo ""
    log_info "仮想環境をPATHに追加する場合 (オプション):"
    log_info "  ${COLOR_GREEN}echo 'export PATH=\"$VENV_PATH/bin:\$PATH\"' >> ~/.bashrc${COLOR_RESET}"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "dry-runモード: 実際の変更は行われませんでした"
    fi
}

# ============================================================================
# 引数解析
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)
                DRY_RUN=true
                log_debug "Dry-runモードを有効化しました"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                log_debug "Verboseモードを有効化しました"
                shift
                ;;
            -p|--venv-path)
                if [[ -z "${2:-}" ]]; then
                    log_error "オプション --venv-path には引数が必要です"
                    usage 2
                fi
                VENV_PATH="$2"
                shift 2
                ;;
            -h|--help)
                usage 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "不明なオプション: $1"
                usage 2
                ;;
            *)
                log_error "予期しない引数: $1"
                usage 2
                ;;
        esac
    done
}

# ============================================================================
# スクリプトエントリーポイント
# ============================================================================

# コマンドライン引数を解析
parse_arguments "$@"

# メインインストールフローを実行
main

exit 0
