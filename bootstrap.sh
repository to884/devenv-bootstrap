#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================================
# Ansible ブートストラップスクリプト (モジュラー版)
# ============================================================================
#
# 目的:
#   リポジトリの初期セットアップ用のクロスディストリビューション対応Ansibleインストールスクリプト。
#   システムPythonを汚染しないよう、Python仮想環境にAnsibleをインストールします。
#   プラットフォーム固有の処理は scripts/platforms/ ディレクトリのハンドラーで実行します。
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
# ============================================================================

# スクリプトの場所を取得
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
readonly PLATFORM_SCRIPTS_DIR="${SCRIPTS_DIR}/platforms"
readonly COMMON_LIB="${SCRIPTS_DIR}/lib/common.sh"

# 設定のデフォルト値
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
VENV_PATH="${VENV_PATH:-${HOME}/.ansible-venv}"
ANSIBLE_PACKAGE="ansible"

# 一時ディレクトリ (終了時にクリーンアップ)
TMPDIR=""

# ============================================================================
# 共通ライブラリの読み込み
# ============================================================================

# 共通ライブラリが存在することを確認
if [[ ! -f "$COMMON_LIB" ]]; then
    echo "ERROR: 共通ライブラリが見つかりません: $COMMON_LIB" >&2
    echo "スクリプトディレクトリの構造が正しくない可能性があります" >&2
    exit 1
fi

# 共通ライブラリを読み込み
# shellcheck source=scripts/lib/common.sh
source "$COMMON_LIB"

# ============================================================================
# プラットフォームハンドラーの動的読み込み
# ============================================================================

load_platform_handler() {
    # プラットフォーム検出とハンドラー読み込み
    
    log_info "プラットフォームを検出中..."
    local distro pkg_mgr platform_handler
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

    # プラットフォーム固有ハンドラーを決定
    case "$pkg_mgr" in
        apt)
            platform_handler="ubuntu-debian.sh"
            ;;
        dnf|yum)
            platform_handler="rhel-fedora.sh"
            ;;
        pacman)
            platform_handler="arch.sh"
            ;;
        *)
            log_error "サポート外のパッケージマネージャー: $pkg_mgr"
            exit 3
            ;;
    esac

    local platform_script="${PLATFORM_SCRIPTS_DIR}/${platform_handler}"
    
    # プラットフォームハンドラーの存在確認
    if [[ ! -f "$platform_script" ]]; then
        log_error "プラットフォームハンドラーが見つかりません: $platform_script"
        log_error "スクリプトディレクトリの構造が正しくない可能性があります"
        exit 1
    fi

    log_info "プラットフォームハンドラーを読み込み中: $platform_handler"
    
    # プラットフォーム固有のスクリプトを読み込み
    # shellcheck source=/dev/null
    source "$platform_script"

    log_debug "プラットフォームハンドラーの読み込みが完了しました"
}

# ============================================================================
# 使用方法とヘルプ
# ============================================================================

usage() {
    local exit_code="${1:-0}"
    local script_name
    script_name="$(basename "${BASH_SOURCE[0]}")"

    cat >&2 <<EOF
使用方法: $script_name [オプション]

リポジトリの初期セットアップ用のクロスディストリビューション対応Ansibleインストールスクリプト。

オプション:
  -d, --dry-run         実際の変更を行わず、実行内容を表示
  -v, --verbose         詳細/デバッグログを有効化
  -p, --venv-path PATH  仮想環境のカスタムパスを指定
                        (デフォルト: \$HOME/.ansible-venv)
  -h, --help            このヘルプメッセージを表示

使用例:
  $script_name                    # デフォルト設定でインストール
  $script_name --dry-run          # 実行内容をプレビュー
  $script_name --verbose          # 詳細ログを表示
  $script_name --venv-path ~/venv # カスタムvenvパスを指定

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

    # 仮想環境のpipパスを検証
    if [[ "$DRY_RUN" != "true" && ! -f "$VENV_PATH/bin/pip" ]]; then
        log_error "仮想環境のpipが見つかりません: $VENV_PATH/bin/pip"
        log_error "仮想環境が正しく作成されていない可能性があります"
        exit 1
    fi
    log_debug "使用するpipパス: $VENV_PATH/bin/pip"

    # 仮想環境内のpipをアップグレード
    log_info "pipをアップグレード中..."
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] 実行予定: $VENV_PATH/bin/pip install --upgrade pip"
    else
        "$VENV_PATH/bin/pip" install --upgrade pip || {
            log_error "pipのアップグレードに失敗しました"
            exit 1
        }
        log_success "pipのアップグレードが完了しました"
    fi

    # Ansibleをインストール
    log_info "Ansibleパッケージをインストール中..."
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] 実行予定: $VENV_PATH/bin/pip install $ANSIBLE_PACKAGE"
    else
        "$VENV_PATH/bin/pip" install "$ANSIBLE_PACKAGE" || {
            log_error "Ansibleのインストールに失敗しました"
            exit 1
        }
        log_success "Ansibleパッケージのインストールが完了しました"
    fi

    # インストール確認
    if [[ "$DRY_RUN" != "true" ]]; then
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
    log_info "Ansibleブートストラップスクリプトを開始しました (モジュラー版)"
    log_debug "スクリプトディレクトリ: $SCRIPT_DIR"
    log_debug "Dry-runモード: $DRY_RUN"
    log_debug "Verboseモード: $VERBOSE"
    log_debug "仮想環境パス: $VENV_PATH"

    # セキュリティチェック: rootでの実行を拒否
    check_not_root

    # プラットフォームハンドラーを動的に読み込み
    load_platform_handler

    # 証明書の更新 (プラットフォーム固有)
    if [[ "$(type -t update_certificates_platform)" == "function" ]]; then
        local certs_dir="${SCRIPT_DIR}/certs"
        local cert_files_found=0
        
        if [[ -d "$certs_dir" ]]; then
            log_debug "証明書ディレクトリをスキャン中: $certs_dir"
            
            # .crt または .pem ファイルを検索
            while IFS= read -r -d '' cert_file; do
                log_info "証明書ファイルを検出: $(basename "$cert_file")"
                update_certificates_platform "$cert_file"
                cert_files_found=$((cert_files_found + 1))
            done < <(find "$certs_dir" -maxdepth 1 -type f \( -name "*.crt" -o -name "*.pem" \) -print0 2>/dev/null)
            
            if [[ $cert_files_found -eq 0 ]]; then
                log_debug "証明書ディレクトリに証明書ファイル (.crt, .pem) が見つかりませんでした (スキップ)"
            else
                log_info "証明書ファイルの処理が完了しました: $cert_files_found 個"
            fi
        else
            log_debug "証明書ディレクトリが見つかりません: $certs_dir (スキップ)"
        fi
    else
        log_debug "プラットフォーム固有の証明書更新関数が見つかりません (スキップ)"
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
        log_info ""
        
        # 実行環境を自動検出してログに出力（既存インストール時も表示）
        log_environment_info
        
        exit 0
    fi

    # システム依存関係をインストール (プラットフォーム固有)
    if [[ "$(type -t install_system_packages_platform)" == "function" ]]; then
        install_system_packages_platform
    else
        log_warning "プラットフォーム固有のシステムパッケージインストール関数が見つかりません"
    fi

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
    log_info "  ${COLOR_GREEN:-}source $VENV_PATH/bin/activate${COLOR_RESET:-}"
    echo ""
    log_info "または、有効化せずにAnsibleを直接実行:"
    log_info "  ${COLOR_GREEN:-}$VENV_PATH/bin/ansible --version${COLOR_RESET:-}"
    log_info "  ${COLOR_GREEN:-}$VENV_PATH/bin/ansible-playbook playbook.yml${COLOR_RESET:-}"
    echo ""
    log_info "仮想環境をPATHに追加する場合 (オプション):"
    log_info "  ${COLOR_GREEN:-}echo 'export PATH=\"$VENV_PATH/bin:\$PATH\"' >> ~/.bashrc${COLOR_RESET:-}"
    echo ""

    # 実行環境を自動検出してログに出力（最後に表示）
    log_environment_info

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