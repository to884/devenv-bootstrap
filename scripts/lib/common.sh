#!/usr/bin/env bash
# ============================================================================
# 共通関数ライブラリ
# ============================================================================
#
# 目的:
#   bootstrap.shで使用する共通機能を提供します
#
# 提供機能:
#   - 統一ログシステム (log_info, log_success, log_error, log_warning, log_debug)
#   - エラーハンドリングとクリーンアップ (cleanup, error_handler)
#   - プラットフォーム検出 (detect_linux_distro, detect_package_manager)
#   - バリデーション機能 (check_not_root, check_python_version, check_dependencies)
#   - Ansibleユーティリティ (is_ansible_installed, get_system_ca_bundle)
#   - 使用方法ヘルプ (usage)
#
# 使用方法:
#   source "${SCRIPT_DIR}/scripts/lib/common.sh"
#
# 必要変数 (読み込み前に設定):
#   SCRIPT_NAME - スクリプト名
#   DRY_RUN     - true/false
#   VERBOSE     - true/false  
#   VENV_PATH   - Ansible仮想環境パス
#   MIN_PYTHON_VERSION - 最小Pythonバージョン
#   ANSIBLE_PACKAGE - Ansibleパッケージ名
#
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# グローバル変数と定数の定義
# ============================================================================

readonly SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[0]}")}"
readonly TIMESTAMP="$(date +'%Y-%m-%d %H:%M:%S')"

# 設定 (未設定の場合のデフォルト値)
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
VENV_PATH="${VENV_PATH:-${HOME}/.ansible-venv}"
MIN_PYTHON_VERSION="${MIN_PYTHON_VERSION:-3.8}"
ANSIBLE_PACKAGE="${ANSIBLE_PACKAGE:-ansible}"

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

# トラップの設定
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
# 証明書バンドル取得
# ============================================================================

get_system_ca_bundle() {
    # システムの証明書バンドルパスを取得
    # 戻り値: 証明書バンドルファイルパス (存在しない場合は空文字列)

    log_debug "システム証明書バンドルパスを検出中..."

    local distro="$1"
    local ca_bundle=""

    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            ca_bundle="/etc/ssl/certs/ca-certificates.crt"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            ca_bundle="/etc/pki/tls/certs/ca-bundle.crt"
            ;;
        arch|manjaro|endeavouros)
            ca_bundle="/etc/ssl/certs/ca-certificates.crt"
            ;;
        *)
            # フォールバック: 一般的なパスを試す
            if [[ -f "/etc/ssl/certs/ca-certificates.crt" ]]; then
                ca_bundle="/etc/ssl/certs/ca-certificates.crt"
            elif [[ -f "/etc/pki/tls/certs/ca-bundle.crt" ]]; then
                ca_bundle="/etc/pki/tls/certs/ca-bundle.crt"
            fi
            ;;
    esac

    if [[ -n "$ca_bundle" && -f "$ca_bundle" ]]; then
        log_debug "検出された証明書バンドル: $ca_bundle"
        echo "$ca_bundle"
    else
        log_debug "システム証明書バンドルが見つかりません"
        echo ""
    fi
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
# Ansible ユーティリティ関数
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

# ============================================================================
# 環境チェック関数
# ============================================================================

check_environment() {
    # 実行環境の基本チェックを実行
    
    log_info "実行環境をチェック中..."
    
    check_not_root
    check_python_version
    check_dependencies
    
    log_success "実行環境チェック完了"
}

# ============================================================================
# 引数解析ヘルパー関数
# ============================================================================

parse_arguments() {
    # 引数解析 (グローバル変数を設定)
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -p|--venv-path)
                VENV_PATH="$2"
                shift 2
                ;;
            -h|--help)
                usage 0
                ;;
            *)
                log_error "不正な引数: $1"
                usage 2
                ;;
        esac
    done
}

# ============================================================================