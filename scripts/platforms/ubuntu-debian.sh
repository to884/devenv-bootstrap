#!/usr/bin/env bash
# ============================================================================
# Ubuntu/Debian (apt) プラットフォーム固有処理
# ============================================================================
#
# 目的:
#   Ubuntu、Debian系ディストリビューション向けの固有処理を提供します
#
# 対応ディストリビューション:
#   - Ubuntu (すべてのバージョン)
#   - Debian (すべてのバージョン)
#   - Linux Mint
#   - Pop!_OS
#   - その他Debian系ディストリビューション
#
# 提供機能:
#   - apt パッケージマネージャーを使用したシステムパッケージインストール
#   - /usr/local/share/ca-certificates/ での証明書管理
#   - update-ca-certificates による証明書バンドル更新
#   - dpkg を使用したパッケージ存在確認
#
# 使用方法:
#   source "${SCRIPT_DIR}/scripts/platforms/ubuntu-debian.sh"
#
# 前提条件:
#   - scripts/lib/common.sh が事前に読み込まれていること
#   - apt コマンドが利用可能であること
#   - sudo 権限（システムパッケージインストール時のみ）
#
# ============================================================================

set -Eeuo pipefail

# ============================================================================
# 証明書管理（Ubuntu/Debian系固有）
# ============================================================================

update_certificates_platform() {
    # Zscaler証明書をシステム証明書ストアに追加・更新 (Ubuntu/Debian系)
    # 引数: $1 = 証明書ファイルパス

    if [[ $# -lt 1 ]]; then
        log_error "update_certificates_platform: 証明書ファイルパスが指定されていません"
        return 1
    fi

    local cert_file="$1"
    local dest="/usr/local/share/ca-certificates/$(basename "$cert_file")"
    local need_update=0

    log_info "証明書を追加中 (Ubuntu/Debian系): $cert_file"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo cp \"$cert_file\" \"$dest\""
        echo "[dry-run] sudo chmod 644 \"$dest\""
        echo "[dry-run] sudo update-ca-certificates"
        return 0
    fi

    # 証明書ファイルをシステム cert ディレクトリにコピー
    if [[ ! -f "$dest" ]] || ! cmp -s "$cert_file" "$dest"; then
        log_debug "証明書ファイルをコピー中: $cert_file -> $dest"
        sudo cp "$cert_file" "$dest"
        sudo chmod 644 "$dest"
        need_update=1
    else
        log_debug "証明書ファイルは既に最新です: $dest"
    fi

    # 証明書バンドルに含まれているか検証
    if ! grep -q "Zscaler" /etc/ssl/certs/ca-certificates.crt 2>/dev/null; then
        log_warning "証明書バンドルにZscaler証明書が含まれていません。更新します..."
        need_update=1
    fi

    # 必要に応じて証明書ストアを更新
    if [[ $need_update -eq 1 ]]; then
        log_info "証明書ストアを更新中 (Ubuntu/Debian系)..."
        sudo update-ca-certificates
        log_success "証明書ストアを更新しました (Ubuntu/Debian系)"
    else
        log_info "証明書バンドルは既に最新です"
    fi
    
    return 0
}

# ============================================================================
# システムパッケージ管理（Ubuntu/Debian系固有）
# ============================================================================

get_system_packages_platform() {
    # Ubuntu/Debian系で必要なシステムパッケージのリストを取得
    # 戻り値: パッケージ名の配列(標準出力)

    echo "python3"
    echo "python3-pip"
    echo "python3-venv"
    echo "build-essential"
    echo "libssl-dev"
    echo "libffi-dev"
}

check_package_installed_platform() {
    # 指定されたパッケージがインストール済みかチェック (Ubuntu/Debian系)
    # 引数: $1 = パッケージ名
    # 戻り値: インストール済みなら0、未インストールなら1

    if [[ $# -lt 1 ]]; then
        log_error "check_package_installed_platform: パッケージ名が指定されていません"
        return 1
    fi

    local package="$1"

    log_debug "パッケージの存在確認 (apt): $package"

    if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        log_debug "パッケージはインストール済み: $package"
        return 0
    else
        log_debug "パッケージは未インストール: $package"
        return 1
    fi
}

get_missing_packages_platform() {
    # インストールされていないシステムパッケージのリストを取得
    # 戻り値: 未インストールパッケージ名の配列(標準出力)

    local -a missing_packages=()

    while IFS= read -r package; do
        if ! check_package_installed_platform "$package"; then
            missing_packages+=("$package")
        fi
    done < <(get_system_packages_platform)

    # 配列の各要素を出力
    printf '%s\n' "${missing_packages[@]}"
}

install_system_packages_platform() {
    # Ansible用のシステムレベル依存関係をインストール (Ubuntu/Debian系)
    # APT パッケージマネージャーを使用

    log_info "システム依存関係をインストール中 (Ubuntu/Debian系)..."

    # 必要なパッケージリストを取得
    local -a packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(get_system_packages_platform)

    log_debug "インストール対象のシステムパッケージ: ${packages[*]}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] sudo apt update && sudo apt install -y ${packages[*]}"
        return 0
    fi

    # インストール済みかチェック
    local -a missing_packages=()
    while IFS= read -r package; do
        [[ -n "$package" ]] && missing_packages+=("$package")
    done < <(get_missing_packages_platform)

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "すべてのシステムパッケージが既にインストール済みです (Ubuntu/Debian系)"
        return 0
    fi

    log_info "不足しているパッケージをインストール中: ${missing_packages[*]}"
    log_warning "sudo権限で以下を実行します:"
    log_warning "  sudo apt update && sudo apt install -y ${missing_packages[*]}"

    # APT パッケージキャッシュを更新
    if ! sudo apt update; then
        log_error "APT パッケージキャッシュの更新に失敗しました"
        return 1
    fi

    # パッケージをインストール
    if ! sudo apt install -y "${missing_packages[@]}"; then
        log_error "システムパッケージのインストールに失敗しました"
        log_warning "手動で以下を実行してください:"
        log_warning "  sudo apt update && sudo apt install -y ${missing_packages[*]}"
        return 1
    fi

    log_success "システムパッケージのインストールが完了しました (Ubuntu/Debian系)"
    return 0
}

# ============================================================================
# プラットフォーム固有のセットアップ関数
# ============================================================================

setup_platform_environment() {
    # Ubuntu/Debian系プラットフォーム固有の環境セットアップ

    log_info "Ubuntu/Debian系プラットフォーム環境をセットアップ中..."

    # 基本的な環境確認
    if ! command -v apt >/dev/null 2>&1; then
        log_error "apt コマンドが見つかりません。Ubuntu/Debian系环境でないか、aptが正しくインストールされていません。"
        return 1
    fi

    log_debug "apt バージョン: $(apt --version 2>/dev/null | head -n1 || echo 'unknown')"
    log_success "Ubuntu/Debian系プラットフォーム環境の確認完了"
    return 0
}

get_platform_info() {
    # プラットフォーム情報を表示

    cat <<EOF
プラットフォーム: Ubuntu/Debian系 (apt)
パッケージマネージャー: apt
証明書ディレクトリ: /usr/local/share/ca-certificates/
証明書更新コマンド: update-ca-certificates
対応ディストリビューション: Ubuntu, Debian, Linux Mint, Pop!_OS
EOF
}

# ============================================================================
# 接続テスト（Ubuntu/Debian系固有）
# ============================================================================

test_certificate_connectivity() {
    # 証明書インストール後の接続テストを実行
    # 引数: なし (デフォルトで www.google.com:443 をテスト)

    local test_host="${1:-www.google.com}"
    local test_port="${2:-443}"

    log_info "証明書インストール後の接続テスト: openssl s_client -connect ${test_host}:${test_port}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] openssl s_client -connect ${test_host}:${test_port} -CApath /etc/ssl/certs"
        return 0
    fi

    if ! openssl s_client -connect "${test_host}:${test_port}" -CApath /etc/ssl/certs < /dev/null 2>/dev/null | grep -q 'Verify return code: 0 (ok)'; then
        log_error "openssl s_client による接続テストに失敗しました (証明書ストアの反映を確認してください)"
        return 1
    else
        log_success "openssl s_client による接続テスト成功 (証明書ストアが有効です)"
        return 0
    fi
}

# ============================================================================
